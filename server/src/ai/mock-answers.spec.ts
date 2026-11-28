import { mockAnswer, type AssistantContext } from './mock-answers.js';

const ctx: AssistantContext = {
  name: 'Ada',
  currency: 'NGN',
  totalBalance: 850000,
  monthIncome: 400000,
  monthExpenses: 150000,
  topCategories: [
    { name: 'Food & Dining', total: 60000 },
    { name: 'Transport', total: 30000 },
  ],
  budgets: [
    { name: 'Food', currency: 'NGN', spent: 60000, amount: 70000, percentageUsed: 85.7 },
  ],
  goals: [
    {
      title: 'Car',
      currency: 'NGN',
      currentAmount: 500000,
      targetAmount: 2000000,
      percentage: 25,
      status: 'AT_RISK',
    },
  ],
  pendingClarifications: 2,
};

describe('mockAnswer', () => {
  it('answers spending questions from real figures', () => {
    const a = mockAnswer('How much did I spend this week?', ctx);
    expect(a.answer).toContain('150,000');
    expect(a.answer).toContain('Food & Dining');
    expect(a.answer).not.toMatch(/32%/); // the old invented figure
  });

  it('flags budgets that are nearly used up', () => {
    expect(mockAnswer("What's my budget status?", ctx).answer).toMatch(
      /Watch Food/,
    );
  });

  it('reports goals and savings rate', () => {
    expect(mockAnswer('Am I on track for my goals?', ctx).answer).toContain(
      'at risk',
    );
    expect(mockAnswer('How much am I saving?', ctx).answer).toContain('63%');
  });

  it('suggests follow-up questions, and is honest with no data', () => {
    expect(mockAnswer('hello', ctx).suggestions.length).toBeGreaterThan(0);
    expect(
      mockAnswer('budget?', { ...ctx, budgets: [] }).answer,
    ).toMatch(/don't have any budgets/);
  });
});
