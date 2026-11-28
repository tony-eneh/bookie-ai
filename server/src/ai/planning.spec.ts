import { computeGoalPlan, computeScenario } from './planning.js';

const now = new Date('2026-11-28T10:00:00Z');

describe('computeGoalPlan', () => {
  it('spreads the remaining amount over the months left', () => {
    const plan = computeGoalPlan(
      {
        targetAmount: 15_000_000,
        targetDate: '2027-11-28',
        currentSavings: 2_800_000,
        monthlyExpenses: 480_000,
        averageIncome: 3_500_000,
      },
      now,
    );
    expect(plan.monthsLeft).toBe(12);
    expect(plan.requiredMonthlySavings).toBeCloseTo(1_016_666.67, 1);
    expect(plan.requiredMonthlyIncome).toBeCloseTo(1_496_666.67, 1);
    expect(plan.riskStatus).toBe('LOW'); // well within 3.02M spare a month
  });

  it('is HIGH risk when it needs more than is left after expenses', () => {
    expect(
      computeGoalPlan(
        {
          targetAmount: 10_000,
          targetDate: '2027-01-28',
          currentSavings: 0,
          monthlyExpenses: 900,
          averageIncome: 1000,
        },
        now,
      ).riskStatus,
    ).toBe('HIGH');
  });
});

describe('computeScenario', () => {
  it('projects six months from next month with a spending cut', () => {
    const s = computeScenario(
      {
        currentBalance: 3_400_000,
        monthlyIncome: 3_500_000,
        monthlyExpenses: 480_000,
        monthlyCut: 100_000,
      },
      now,
    );
    expect(s.baselineMonthlyNet).toBe(3_020_000);
    expect(s.monthlyNet).toBe(3_120_000);
    expect(s.projections[0]).toEqual({ month: '2026-12', balance: 6_520_000 });
    expect(s.projections[5].month).toBe('2027-05');
  });

  it('supports a direct monthly change', () => {
    expect(computeScenario({ currentBalance: 100, monthlyChange: 50 }, now).projections[1].balance).toBe(200);
  });
});
