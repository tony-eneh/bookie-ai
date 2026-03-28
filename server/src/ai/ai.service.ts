import { Injectable, Logger } from '@nestjs/common';

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

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  async parseTransaction(rawText: string): Promise<ParsedTransaction> {
    const prompt = `Parse this financial message and extract transaction details: "${rawText}"`;
    const systemPrompt =
      'You are a financial transaction parser. Extract structured data from raw text.';
    return this.callLLM<ParsedTransaction>(prompt, systemPrompt, () =>
      this.mockParseTransaction(rawText),
    );
  }

  async classifyCategory(
    description: string,
    merchantName?: string,
  ): Promise<CategoryClassification> {
    const prompt = `Classify the category for: description="${description}", merchant="${merchantName ?? 'unknown'}"`;
    const systemPrompt =
      'You are a financial category classifier.';
    return this.callLLM<CategoryClassification>(prompt, systemPrompt, () =>
      this.mockClassifyCategory(description, merchantName),
    );
  }

  async generateClarificationQuestion(transaction: {
    description?: string;
    merchantName?: string;
    amount?: number;
    type?: string;
  }): Promise<ClarificationQuestion> {
    const prompt = `Generate a clarification question for transaction: ${JSON.stringify(transaction)}`;
    const systemPrompt =
      'You are a helpful financial assistant asking for clarification.';
    return this.callLLM<ClarificationQuestion>(prompt, systemPrompt, () =>
      this.mockClarificationQuestion(transaction),
    );
  }

  async answerFinanceQuestion(
    question: string,
    userData: Record<string, unknown>,
  ): Promise<FinanceAnswer> {
    const prompt = `Answer this finance question: "${question}" given user data: ${JSON.stringify(userData)}`;
    const systemPrompt =
      'You are a personal finance assistant. Answer clearly and suggest actions.';
    return this.callLLM<FinanceAnswer>(prompt, systemPrompt, () =>
      this.mockAnswerFinance(question),
    );
  }

  async generateSummary(
    type: 'weekly' | 'monthly',
    data: Record<string, unknown>,
  ): Promise<Summary> {
    const prompt = `Generate a ${type} financial summary from: ${JSON.stringify(data)}`;
    const systemPrompt =
      'You are a financial report generator. Provide actionable summaries.';
    return this.callLLM<Summary>(prompt, systemPrompt, () =>
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
    const systemPrompt =
      'You are a financial goal planning advisor.';
    return this.callLLM<GoalPlan>(prompt, systemPrompt, () =>
      this.mockPlanGoal(input),
    );
  }

  async simulateScenario(input: {
    scenarioType: string;
    parameters: Record<string, unknown>;
  }): Promise<ScenarioResult> {
    const prompt = `Simulate financial scenario: ${JSON.stringify(input)}`;
    const systemPrompt =
      'You are a financial scenario simulator.';
    return this.callLLM<ScenarioResult>(prompt, systemPrompt, () =>
      this.mockSimulateScenario(input),
    );
  }

  async simulateFx(input: {
    amount: number;
    sourceCurrency: string;
    targetCurrency: string;
  }): Promise<FxSimulationResult> {
    const prompt = `Simulate FX conversion: ${JSON.stringify(input)}`;
    const systemPrompt = 'You are an FX conversion assistant.';
    return this.callLLM<FxSimulationResult>(prompt, systemPrompt, () =>
      this.mockSimulateFx(input),
    );
  }

  // In the future this calls an actual LLM API; for now it returns mock data.
  private async callLLM<T>(
    _prompt: string,
    _systemPrompt: string,
    mockFn: () => T,
  ): Promise<T> {
    this.logger.debug('AI mock mode – returning structured mock response');
    return mockFn();
  }

  // ─── Mock implementations ──────────────────────────────────────────────────

  private mockParseTransaction(rawText: string): ParsedTransaction {
    const lower = rawText.toLowerCase();
    const amountMatch = rawText.match(/[\d,]+\.?\d*/);
    const amount = amountMatch
      ? parseFloat(amountMatch[0].replace(/,/g, ''))
      : 0;

    const isIncome =
      lower.includes('received') ||
      lower.includes('credited') ||
      lower.includes('salary') ||
      lower.includes('deposit');
    const isTransfer =
      lower.includes('transfer') || lower.includes('sent to');

    const currencyMatch = rawText.match(
      /\b(USD|EUR|GBP|NGN|KES|GHS|ZAR|CAD|AUD|JPY)\b/i,
    );

    const merchantPatterns = [
      { pattern: /(?:at|from|to)\s+([A-Z][\w\s&'-]+)/i, group: 1 },
      { pattern: /(?:merchant|shop|store):\s*([^\n,]+)/i, group: 1 },
    ];
    let merchantName: string | null = null;
    for (const { pattern, group } of merchantPatterns) {
      const match = rawText.match(pattern);
      if (match) {
        merchantName = match[group].trim();
        break;
      }
    }

    const ambiguityFlags: string[] = [];
    if (amount === 0) ambiguityFlags.push('AMOUNT_UNCLEAR');
    if (!merchantName) ambiguityFlags.push('MERCHANT_UNKNOWN');
    if (!isIncome && !isTransfer && !lower.includes('debit') && !lower.includes('spent'))
      ambiguityFlags.push('TYPE_AMBIGUOUS');

    const confidence = Math.max(0.4, 1 - ambiguityFlags.length * 0.2);

    return {
      amount: amount || 25.0,
      currency: currencyMatch ? currencyMatch[0].toUpperCase() : 'USD',
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
      rent: 'Rent & Housing',
      electricity: 'Utilities',
      water: 'Utilities',
      internet: 'Utilities',
      salary: 'Salary',
      freelance: 'Freelance Income',
      netflix: 'Subscriptions',
      spotify: 'Subscriptions',
      airtime: 'Phone & Internet',
      data: 'Phone & Internet',
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

  private mockAnswerFinance(question: string): FinanceAnswer {
    const lower = question.toLowerCase();

    if (lower.includes('spend') || lower.includes('spending')) {
      return {
        answer:
          'Based on your recent transactions, your top spending categories this month are Food & Dining (32%), Transport (18%), and Subscriptions (12%). You are within budget for most categories.',
        suggestions: [
          'Review your dining expenses',
          'Consider meal-prepping to save on food costs',
          'Check for unused subscriptions',
        ],
        actionRequired: undefined,
      };
    }

    if (lower.includes('save') || lower.includes('savings')) {
      return {
        answer:
          'Your current savings rate is approximately 15% of your income. Financial experts recommend saving at least 20%. Consider automating transfers to your savings account.',
        suggestions: [
          'Set up automatic savings transfers',
          'Review subscriptions for potential cuts',
          'Create a dedicated savings goal',
        ],
        actionRequired: 'Create a savings goal to track progress',
      };
    }

    return {
      answer: `Great question! Based on your financial data, here's what I can tell you: Your finances are generally healthy with a positive cash flow trend. Keep monitoring your spending against your budget limits.`,
      suggestions: [
        'Review your monthly dashboard',
        'Check budget progress',
        'Update your financial goals',
      ],
      actionRequired: undefined,
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
    const months = ['Month 1', 'Month 2', 'Month 3', 'Month 4', 'Month 5', 'Month 6'];
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
