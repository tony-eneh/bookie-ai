import type { FinanceAnswer } from './ai.service.js';

/** What the assistant knows about the user (all amounts already converted). */
export interface AssistantContext {
  name?: string | null;
  currency: string;
  totalBalance: number;
  monthIncome: number;
  monthExpenses: number;
  topCategories: { name: string; total: number }[];
  budgets: {
    name: string;
    currency: string;
    spent: number;
    amount: number;
    percentageUsed: number;
  }[];
  goals: {
    title: string;
    currency: string;
    currentAmount: number;
    targetAmount: number;
    percentage: number;
    status: string;
  }[];
  pendingClarifications: number;
}

const FOLLOW_UPS = {
  spending: 'What did I spend the most on?',
  budgets: 'How are my budgets doing?',
  goals: 'Am I on track for my goals?',
  saving: 'How much am I saving?',
  balance: "What's my total balance?",
};

function money(amount: number, currency: string): string {
  try {
    return new Intl.NumberFormat('en', {
      style: 'currency',
      currency,
      maximumFractionDigits: Math.abs(amount) >= 1000 ? 0 : 2,
    }).format(amount);
  } catch {
    return `${currency} ${amount.toFixed(2)}`;
  }
}

function followUps(...keys: (keyof typeof FOLLOW_UPS)[]): string[] {
  return keys.map((k) => FOLLOW_UPS[k]);
}

/**
 * Answers common questions from the user's real figures when no AI provider
 * is configured. Never invents numbers: if the data isn't there, it says so.
 */
export function mockAnswer(
  question: string,
  partial: Partial<AssistantContext>,
): FinanceAnswer {
  const ctx: AssistantContext = {
    currency: 'USD',
    totalBalance: 0,
    monthIncome: 0,
    monthExpenses: 0,
    topCategories: [],
    budgets: [],
    goals: [],
    pendingClarifications: 0,
    ...partial,
  };
  const q = question.toLowerCase();
  const m = (v: number) => money(v, ctx.currency);

  if (/budget/.test(q)) {
    if (ctx.budgets.length === 0) {
      return {
        answer:
          "You don't have any budgets yet. Set one for a category you want to keep an eye on, like food or transport.",
        suggestions: followUps('spending', 'saving'),
      };
    }
    const lines = ctx.budgets.map(
      (b) =>
        `${b.name}: ${money(b.spent, b.currency)} of ${money(b.amount, b.currency)} (${b.percentageUsed.toFixed(0)}%)`,
    );
    const tight = ctx.budgets.filter((b) => b.percentageUsed >= 80);
    return {
      answer:
        `Here's where your budgets stand this period:\n${lines.join('\n')}` +
        (tight.length
          ? `\n\nWatch ${tight.map((b) => b.name).join(' and ')}: ${tight.length === 1 ? "it's" : "they're"} nearly used up.`
          : '\n\nEverything is within budget.'),
      suggestions: followUps('spending', 'goals'),
    };
  }

  if (/goal|on track|target/.test(q)) {
    if (ctx.goals.length === 0) {
      return {
        answer:
          "You haven't set any goals yet. Tell Bookie what you're saving for and it will track your pace.",
        suggestions: followUps('saving', 'spending'),
      };
    }
    const lines = ctx.goals.map(
      (g) =>
        `${g.title}: ${money(g.currentAmount, g.currency)} of ${money(g.targetAmount, g.currency)} (${g.percentage.toFixed(0)}%, ${g.status.replace('_', ' ').toLowerCase()})`,
    );
    return {
      answer: `Your goals:\n${lines.join('\n')}`,
      suggestions: followUps('saving', 'budgets'),
    };
  }

  if (/spend|spent|expense|cost/.test(q)) {
    const top = ctx.topCategories.slice(0, 3);
    return {
      answer:
        ctx.monthExpenses > 0
          ? `This month you've spent ${m(ctx.monthExpenses)}.` +
            (top.length
              ? ` Most of it went on ${top.map((c) => `${c.name} (${m(c.total)})`).join(', ')}.`
              : '')
          : "You haven't recorded any spending this month yet.",
      suggestions: followUps('budgets', 'saving'),
    };
  }

  if (/sav/.test(q)) {
    const net = ctx.monthIncome - ctx.monthExpenses;
    const rate = ctx.monthIncome > 0 ? (net / ctx.monthIncome) * 100 : null;
    return {
      answer:
        rate === null
          ? `No income recorded this month yet, so there's no savings rate to show. Spending so far: ${m(ctx.monthExpenses)}.`
          : `This month you've earned ${m(ctx.monthIncome)} and spent ${m(ctx.monthExpenses)}, so you're keeping ${m(net)} (${rate.toFixed(0)}% of your income).`,
      suggestions: followUps('goals', 'spending'),
    };
  }

  if (/income|earn|salary|made/.test(q)) {
    return {
      answer: `You've received ${m(ctx.monthIncome)} so far this month.`,
      suggestions: followUps('saving', 'spending'),
    };
  }

  if (/balance|how much (do|have) i|net worth|total/.test(q)) {
    return {
      answer: `Across all your accounts you have about ${m(ctx.totalBalance)}.`,
      suggestions: followUps('spending', 'goals'),
    };
  }

  const pending =
    ctx.pendingClarifications > 0
      ? ` Bookie also has ${ctx.pendingClarifications} question${ctx.pendingClarifications === 1 ? '' : 's'} for you about recent transactions.`
      : '';
  return {
    answer:
      `Here's your month so far: ${m(ctx.monthIncome)} in, ${m(ctx.monthExpenses)} out, ` +
      `and ${m(ctx.totalBalance)} across your accounts.${pending}`,
    suggestions: followUps('spending', 'budgets', 'goals'),
  };
}
