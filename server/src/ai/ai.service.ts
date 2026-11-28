import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { checkShape, describeShape, type ShapeSpec } from './ai-shape.js';
import { mockAnswer, type AssistantContext } from './mock-answers.js';

class ProviderAuthError extends Error {}

export interface ParsedTransaction {
  amount: number;
  currency: string;
  type: 'INCOME' | 'EXPENSE' | 'TRANSFER';
  merchantName: string | null;
  counterparty: string | null;
  occurredAt: string;
  categoryGuess: string | null;
  description: string;
  confidence: number;
  ambiguityFlags: string[];
}

export interface CategoryClassification {
  categoryName: string;
  confidence: number;
  alternatives: { name: string; confidence: number }[];
}

export interface ClarificationQuestion {
  questionText: string;
  suggestedOptions: string[];
}

export interface FinanceAnswer {
  answer: string;
  suggestions: string[];
  actionRequired?: string;
}

export interface Summary {
  title: string;
  body: string;
  highlights: string[];
  recommendations: string[];
}

export interface GoalPlan {
  requiredMonthlySavings: number;
  requiredMonthlyIncome: number;
  riskStatus: 'LOW' | 'MEDIUM' | 'HIGH';
  coachingAdvice: string;
}

export interface ScenarioResult {
  projections: { month: string; balance: number }[];
  explanation: string;
  recommendedAction: string;
}

export interface FxSimulationResult {
  convertedAmount: number;
  rateUsed: number;
  explanation: string;
}

const SHAPES = {
  parsedTransaction: {
    amount: 'number',
    currency: 'string',
    type: 'enum:INCOME|EXPENSE|TRANSFER',
    merchantName: 'string|null',
    counterparty: 'string|null',
    occurredAt: 'string',
    categoryGuess: 'string|null',
    description: 'string',
    confidence: 'number',
    ambiguityFlags: 'string[]',
  },
  category: {
    categoryName: 'string',
    confidence: 'number',
    alternatives: 'array',
  },
  clarification: { questionText: 'string', suggestedOptions: 'string[]' },
  financeAnswer: {
    answer: 'string',
    suggestions: 'string[]',
    actionRequired: 'string?',
  },
  summary: {
    title: 'string',
    body: 'string',
    highlights: 'string[]',
    recommendations: 'string[]',
  },
  goalPlan: {
    requiredMonthlySavings: 'number',
    requiredMonthlyIncome: 'number',
    riskStatus: 'enum:LOW|MEDIUM|HIGH',
    coachingAdvice: 'string',
  },
  scenario: {
    projections: 'array',
    explanation: 'string',
    recommendedAction: 'string',
  },
  fx: { convertedAmount: 'number', rateUsed: 'number', explanation: 'string' },
} satisfies Record<string, ShapeSpec>;

/** Values that mean "no real key configured" (e.g. the old prod placeholder). */
export function isPlaceholderApiKey(key: string | undefined): boolean {
  if (!key || !key.trim()) return true;
  return /^(mock|none|disabled|placeholder|changeme|your[_-])/i.test(
    key.trim(),
  );
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  /** Set after the provider rejects our key, to skip pointless round trips. */
  private providerDisabledUntil = 0;

  constructor(private configService: ConfigService) {}

  async parseTransaction(
    rawText: string,
    opts: { defaultCurrency?: string } = {},
  ): Promise<ParsedTransaction> {
    const defaultCurrency = opts.defaultCurrency ?? 'USD';
    const prompt = `Parse this financial message and extract the transaction: "${rawText}"
Today is ${new Date().toISOString()}. If no currency is stated, use ${defaultCurrency}.
"amount" is always positive; "type" says the direction. "occurredAt" is an ISO 8601 date-time.
"confidence" is 0 to 1. "ambiguityFlags" may include AMOUNT_UNCLEAR, MERCHANT_UNKNOWN, TYPE_AMBIGUOUS, DATE_UNCLEAR.`;
    const systemPrompt =
      'You are a financial transaction parser. Extract structured data from bank alerts, receipts and notes.';
    return this.callLLM<ParsedTransaction>(
      prompt,
      systemPrompt,
      SHAPES.parsedTransaction,
      () => this.mockParseTransaction(rawText, defaultCurrency),
    );
  }

  async classifyCategory(
    description: string,
    merchantName?: string,
  ): Promise<CategoryClassification> {
    const prompt = `Classify the spending/income category for: description="${description}", merchant="${merchantName ?? 'unknown'}".
"alternatives" is a list of {"name": string, "confidence": number}.`;
    const systemPrompt = 'You are a financial category classifier.';
    return this.callLLM<CategoryClassification>(
      prompt,
      systemPrompt,
      SHAPES.category,
      () => this.mockClassifyCategory(description, merchantName),
    );
  }

  async generateClarificationQuestion(transaction: {
    description?: string;
    merchantName?: string;
    amount?: number;
    type?: string;
  }): Promise<ClarificationQuestion> {
    const prompt = `Write one short question asking the user to clarify this transaction, with 2 to 4 tappable answer options: ${JSON.stringify(transaction)}`;
    const systemPrompt =
      'You are a friendly financial assistant asking for a quick clarification.';
    return this.callLLM<ClarificationQuestion>(
      prompt,
      systemPrompt,
      SHAPES.clarification,
      () => this.mockClarificationQuestion(transaction),
    );
  }

  async answerFinanceQuestion(
    question: string,
    userData: Record<string, unknown>,
  ): Promise<FinanceAnswer> {
    const prompt = `Answer this finance question: "${question}"
Use only the user's data below. If the data doesn't contain the answer, say so instead of guessing. Never invent figures.
User data: ${JSON.stringify(userData)}
"suggestions" are 0 to 3 short follow-up questions the user could ask next.`;
    const systemPrompt =
      "You are a personal finance assistant. Answer clearly and concisely, using the user's own currency.";
    return this.callLLM<FinanceAnswer>(
      prompt,
      systemPrompt,
      SHAPES.financeAnswer,
      () => mockAnswer(question, userData as Partial<AssistantContext>),
    );
  }

  async generateSummary(
    type: 'weekly' | 'monthly',
    data: Record<string, unknown>,
  ): Promise<Summary> {
    const prompt = `Generate a ${type} financial summary from this data. Use only these figures: ${JSON.stringify(data)}`;
    const systemPrompt =
      'You are a financial report generator. Provide short, actionable summaries.';
    return this.callLLM<Summary>(prompt, systemPrompt, SHAPES.summary, () =>
      this.mockSummary(type, data),
    );
  }

  async planGoal(input: {
    targetAmount: number;
    targetDate: string;
    currentSavings: number;
    monthlyExpenses: number;
    averageIncome: number;
  }): Promise<GoalPlan> {
    const prompt = `Plan a savings goal: ${JSON.stringify(input)}`;
    const systemPrompt = 'You are a financial goal planning advisor.';
    return this.callLLM<GoalPlan>(prompt, systemPrompt, SHAPES.goalPlan, () =>
      this.mockPlanGoal(input),
    );
  }

  async simulateScenario(input: {
    scenarioType: string;
    parameters: Record<string, unknown>;
  }): Promise<ScenarioResult> {
    const prompt = `Simulate this financial scenario over the next 6 months: ${JSON.stringify(input)}
"projections" is a list of {"month": "YYYY-MM", "balance": number}.`;
    const systemPrompt = 'You are a financial scenario simulator.';
    return this.callLLM<ScenarioResult>(
      prompt,
      systemPrompt,
      SHAPES.scenario,
      () => this.mockSimulateScenario(input),
    );
  }

  async simulateFx(input: {
    amount: number;
    sourceCurrency: string;
    targetCurrency: string;
  }): Promise<FxSimulationResult> {
    const prompt = `Simulate FX conversion: ${JSON.stringify(input)}`;
    const systemPrompt = 'You are an FX conversion assistant.';
    return this.callLLM<FxSimulationResult>(
      prompt,
      systemPrompt,
      SHAPES.fx,
      () => this.mockSimulateFx(input),
    );
  }

  /** True when a real AI provider is configured and currently usable. */
  isLive(): boolean {
    return (
      !isPlaceholderApiKey(this.configService.get<string>('OPENAI_API_KEY')) &&
      Date.now() >= this.providerDisabledUntil
    );
  }

  private async callLLM<T>(
    prompt: string,
    systemPrompt: string,
    shape: ShapeSpec,
    mockFn: () => T,
  ): Promise<T> {
    if (!this.isLive()) {
      return mockFn();
    }

    try {
      const responseText = await this.callOpenAiCompatibleApi(
        `${systemPrompt}\n\n${describeShape(shape)}`,
        `${prompt}\n\nReturn only valid JSON. Do not wrap it in markdown.`,
      );
      return checkShape<T>(JSON.parse(responseText), shape);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      if (error instanceof ProviderAuthError) {
        this.providerDisabledUntil = Date.now() + 10 * 60 * 1000;
        this.logger.error(`${message}. Using mock AI for the next 10 minutes.`);
      } else {
        this.logger.warn(`AI call failed, falling back to mock: ${message}`);
      }
      return mockFn();
    }
  }

  private async callOpenAiCompatibleApi(
    systemPrompt: string,
    userPrompt: string,
  ) {
    const apiKey = this.configService.getOrThrow<string>('OPENAI_API_KEY');
    const model =
      this.configService.get<string>('OPENAI_MODEL') ?? 'gpt-4o-mini';
    const baseUrl = (
      this.configService.get<string>('OPENAI_BASE_URL') ??
      'https://api.openai.com/v1'
    ).replace(/\/$/, '');

    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: 'POST',
      signal: AbortSignal.timeout(20_000),
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt },
        ],
      }),
    });

    if (response.status === 401 || response.status === 403) {
      throw new ProviderAuthError(
        `AI provider rejected the API key (status ${response.status})`,
      );
    }
    if (!response.ok) {
      throw new Error(`AI provider responded with status ${response.status}`);
    }

    const payload = (await response.json()) as {
      choices?: Array<{
        message?: {
          content?: string | Array<{ type?: string; text?: string }>;
        };
      }>;
    };
    const firstChoice = payload.choices?.[0]?.message?.content;

    if (typeof firstChoice === 'string') {
      return firstChoice;
    }

    if (Array.isArray(firstChoice)) {
      const textContent = firstChoice
        .filter((item) => item.type === 'text' && item.text)
        .map((item) => item.text)
        .join('');

      if (textContent) {
        return textContent;
      }
    }

    throw new Error('AI provider returned an empty response');
  }

  // ─── Mock implementations ──────────────────────────────────────────────────

  private mockParseTransaction(
    rawText: string,
    defaultCurrency: string,
  ): ParsedTransaction {
    const lower = rawText.toLowerCase();
    // Prefer a number next to a currency ("NGN 6,800.00", "4,500 KRW"),
    // never masked digits like "Acct ***4521"; then any number ("20k").
    const unmasked = rawText.replace(/[*xX#]+\d+/g, ' ');
    const currencyAmount =
      unmasked.match(
        /(?:\b(?:NGN|USD|EUR|GBP|KRW|KES|GHS|ZAR|CAD|AUD|JPY|INR|CNY)|[₦$₩€£])\s?(\d[\d,]*(?:\.\d+)?)/i,
      ) ??
      unmasked.match(
        /(\d[\d,]*(?:\.\d+)?)\s?(?:NGN|USD|EUR|GBP|KRW|KES|GHS|ZAR|naira|dollars?)\b/i,
      );
    const amountMatch = currencyAmount
      ? [currencyAmount[0], currencyAmount[1], undefined]
      : unmasked.match(/(\d[\d,]*(?:\.\d+)?)\s*(k|m)?\b/i);
    const multiplier =
      amountMatch?.[2]?.toLowerCase() === 'k'
        ? 1_000
        : amountMatch?.[2]?.toLowerCase() === 'm'
          ? 1_000_000
          : 1;
    const amount = amountMatch?.[1]
      ? parseFloat(amountMatch[1].replace(/,/g, '')) * multiplier
      : 0;

    const isIncome =
      lower.includes('received') ||
      lower.includes('credited') ||
      lower.includes('salary') ||
      lower.includes('deposit');
    const isTransfer = lower.includes('transfer') || lower.includes('sent to');

    const currencyMatch = rawText.match(
      /\b(USD|EUR|GBP|NGN|KES|GHS|ZAR|CAD|AUD|JPY|KRW|INR|CNY)\b/i,
    );

    const merchantPatterns = [
      { pattern: /(?:at|from|to)\s+([A-Z][\w\s&'-]+)/i, group: 1 },
      { pattern: /(?:merchant|shop|store):\s*([^\n,]+)/i, group: 1 },
    ];
    let merchantName: string | null = null;
    for (const { pattern, group } of merchantPatterns) {
      const match = rawText.match(pattern);
      if (match) {
        // Alerts run on into the date/reference: "SPAR VI on 28-11-2026".
        merchantName =
          match[group]
            .replace(/\s+(on|ref|via|date)\b.*$/i, '')
            .replace(/[\s.,-]+$/, '')
            .trim() || null;
        break;
      }
    }

    const ambiguityFlags: string[] = [];
    if (amount === 0) ambiguityFlags.push('AMOUNT_UNCLEAR');
    if (!merchantName) ambiguityFlags.push('MERCHANT_UNKNOWN');
    if (
      !isIncome &&
      !isTransfer &&
      !lower.includes('debit') &&
      !lower.includes('spent')
    )
      ambiguityFlags.push('TYPE_AMBIGUOUS');

    const confidence = Math.max(0.4, 1 - ambiguityFlags.length * 0.2);

    return {
      amount,
      currency: currencyMatch
        ? currencyMatch[0].toUpperCase()
        : defaultCurrency,
      type: isIncome ? 'INCOME' : isTransfer ? 'TRANSFER' : 'EXPENSE',
      merchantName,
      counterparty: merchantName,
      occurredAt: new Date().toISOString(),
      categoryGuess: this.guessCategoryFromText(lower),
      description: rawText.substring(0, 200),
      confidence,
      ambiguityFlags,
    };
  }

  private guessCategoryFromText(lower: string): string | null {
    const map: Record<string, string> = {
      food: 'Food & Dining',
      restaurant: 'Food & Dining',
      cafe: 'Food & Dining',
      coffee: 'Food & Dining',
      grocery: 'Groceries',
      supermarket: 'Groceries',
      uber: 'Transport',
      lyft: 'Transport',
      taxi: 'Transport',
      fuel: 'Transport',
      rent: 'Rent',
      electricity: 'Utilities',
      water: 'Utilities',
      internet: 'Internet',
      salary: 'Salary',
      freelance: 'Freelance',
      netflix: 'Subscriptions',
      spotify: 'Subscriptions',
      airtime: 'Mobile/Data',
      'data bundle': 'Mobile/Data',
      hospital: 'Healthcare',
      pharmacy: 'Healthcare',
      school: 'Education',
      tuition: 'Education',
    };
    for (const [keyword, category] of Object.entries(map)) {
      if (lower.includes(keyword)) return category;
    }
    return null;
  }

  private mockClassifyCategory(
    description: string,
    merchantName?: string,
  ): CategoryClassification {
    const combined = `${description} ${merchantName ?? ''}`.toLowerCase();
    const guess = this.guessCategoryFromText(combined);

    return {
      categoryName: guess ?? 'Miscellaneous',
      confidence: guess ? 0.82 : 0.45,
      alternatives: [
        { name: guess ? 'Miscellaneous' : 'Food & Dining', confidence: 0.35 },
        { name: 'Shopping', confidence: 0.2 },
      ],
    };
  }

  private mockClarificationQuestion(transaction: {
    description?: string;
    merchantName?: string;
    amount?: number;
    type?: string;
  }): ClarificationQuestion {
    const desc = transaction.description ?? 'this transaction';
    const merchant = transaction.merchantName;

    if (merchant) {
      return {
        questionText: `I noticed a transaction of ${transaction.amount ?? 'an unknown amount'} at "${merchant}". What category does this belong to?`,
        suggestedOptions: [
          'Food & Dining',
          'Shopping',
          'Transport',
          'Subscriptions',
          'Other',
        ],
      };
    }

    return {
      questionText: `I parsed "${desc}" but I'm not fully confident. Could you confirm the transaction type and category?`,
      suggestedOptions: ['Expense', 'Income', 'Transfer', 'Skip'],
    };
  }



  private mockSummary(
    type: 'weekly' | 'monthly',
    data: Record<string, unknown>,
  ): Summary {
    const income = (data.totalIncome as number) ?? 3500;
    const expenses = (data.totalExpenses as number) ?? 2100;
    const net = income - expenses;

    if (type === 'weekly') {
      return {
        title: 'Your Weekly Financial Summary',
        body: `This week you earned ${income.toFixed(2)} and spent ${expenses.toFixed(2)}, resulting in a net cash flow of ${net.toFixed(2)}. Your spending is ${net >= 0 ? 'within' : 'above'} your income.`,
        highlights: [
          `Net cash flow: ${net >= 0 ? '+' : ''}${net.toFixed(2)}`,
          `Top expense category: Food & Dining`,
          `${expenses > income ? 'Warning: You spent more than you earned' : 'Great job staying within budget!'}`,
        ],
        recommendations: [
          'Track daily expenses to stay on top of spending',
          'Review upcoming bills for the next week',
        ],
      };
    }

    return {
      title: 'Your Monthly Financial Report',
      body: `This month you earned ${income.toFixed(2)} and spent ${expenses.toFixed(2)}. Your savings rate is ${((net / income) * 100).toFixed(1)}%. ${net >= 0 ? 'You are saving money each month.' : 'Consider reducing expenses to avoid a deficit.'}`,
      highlights: [
        `Total income: ${income.toFixed(2)}`,
        `Total expenses: ${expenses.toFixed(2)}`,
        `Savings rate: ${((net / income) * 100).toFixed(1)}%`,
        `Net cash flow: ${net >= 0 ? '+' : ''}${net.toFixed(2)}`,
      ],
      recommendations: [
        'Consider increasing your emergency fund',
        'Review category-level budgets for next month',
        'Set a savings goal if you have not already',
      ],
    };
  }

  private mockPlanGoal(input: {
    targetAmount: number;
    targetDate: string;
    currentSavings: number;
    monthlyExpenses: number;
    averageIncome: number;
  }): GoalPlan {
    const remaining = input.targetAmount - input.currentSavings;
    const targetDate = new Date(input.targetDate);
    const now = new Date();
    const months = Math.max(
      1,
      (targetDate.getFullYear() - now.getFullYear()) * 12 +
        (targetDate.getMonth() - now.getMonth()),
    );

    const requiredMonthlySavings = Number((remaining / months).toFixed(2));
    const requiredMonthlyIncome = Number(
      (input.monthlyExpenses + requiredMonthlySavings).toFixed(2),
    );

    const ratio = requiredMonthlySavings / (input.averageIncome || 1);
    const riskStatus: 'LOW' | 'MEDIUM' | 'HIGH' =
      ratio < 0.2 ? 'LOW' : ratio < 0.4 ? 'MEDIUM' : 'HIGH';

    let coachingAdvice: string;
    if (riskStatus === 'LOW') {
      coachingAdvice = `You're in great shape! Saving ${requiredMonthlySavings} per month is very achievable given your income. Stay consistent!`;
    } else if (riskStatus === 'MEDIUM') {
      coachingAdvice = `This goal is achievable but will require discipline. Consider cutting discretionary spending by 10-15% to stay on track.`;
    } else {
      coachingAdvice = `This is an ambitious goal. You may need to extend your timeline or find additional income sources. Consider breaking it into smaller milestones.`;
    }

    return {
      requiredMonthlySavings,
      requiredMonthlyIncome,
      riskStatus,
      coachingAdvice,
    };
  }

  private mockSimulateScenario(input: {
    scenarioType: string;
    parameters: Record<string, unknown>;
  }): ScenarioResult {
    const months = [
      'Month 1',
      'Month 2',
      'Month 3',
      'Month 4',
      'Month 5',
      'Month 6',
    ];
    const baseBalance = (input.parameters.currentBalance as number) ?? 5000;
    const monthlyChange = (input.parameters.monthlyChange as number) ?? 200;

    const projections = months.map((month, i) => ({
      month,
      balance: Number((baseBalance + monthlyChange * (i + 1)).toFixed(2)),
    }));

    const scenarioDescriptions: Record<string, string> = {
      salary_increase: `With the projected salary increase, your balance would grow steadily over 6 months, reaching ${projections[5].balance}.`,
      expense_reduction: `Reducing expenses as planned would allow you to save an additional ${monthlyChange * 6} over 6 months.`,
      investment: `Based on estimated returns, your investment could grow to ${projections[5].balance} in 6 months.`,
    };

    return {
      projections,
      explanation:
        scenarioDescriptions[input.scenarioType] ??
        `Under this scenario, your projected balance after 6 months would be ${projections[5].balance}. This assumes steady monthly changes of ${monthlyChange}.`,
      recommendedAction:
        'Monitor progress monthly and adjust your budget if actual results deviate by more than 10% from projections.',
    };
  }

  private mockSimulateFx(input: {
    amount: number;
    sourceCurrency: string;
    targetCurrency: string;
  }): FxSimulationResult {
    const rates: Record<string, number> = {
      'USD-EUR': 0.92,
      'USD-GBP': 0.79,
      'USD-NGN': 1550.0,
      'USD-KES': 153.5,
      'USD-GHS': 15.2,
      'USD-ZAR': 18.1,
      'USD-CAD': 1.36,
      'USD-JPY': 154.8,
      'EUR-USD': 1.09,
      'GBP-USD': 1.27,
      'NGN-USD': 0.00065,
    };

    const pair = `${input.sourceCurrency}-${input.targetCurrency}`;
    const reversePair = `${input.targetCurrency}-${input.sourceCurrency}`;

    let rateUsed: number;
    if (input.sourceCurrency === input.targetCurrency) {
      rateUsed = 1.0;
    } else if (rates[pair]) {
      rateUsed = rates[pair];
    } else if (rates[reversePair]) {
      rateUsed = Number((1 / rates[reversePair]).toFixed(6));
    } else {
      rateUsed = 1.0;
    }

    const convertedAmount = Number((input.amount * rateUsed).toFixed(2));

    return {
      convertedAmount,
      rateUsed,
      explanation: `${input.amount} ${input.sourceCurrency} converts to ${convertedAmount} ${input.targetCurrency} at a rate of ${rateUsed}. Note: This is a simulated rate for planning purposes. Actual rates may vary.`,
    };
  }
}
