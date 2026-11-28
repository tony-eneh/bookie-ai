/**
 * Deterministic money maths for goal plans and what-if scenarios. The model
 * only writes the words around these numbers: it is unreliable at arithmetic
 * and dates (it projected balances from 2023 in testing).
 */

export interface GoalPlanInput {
  targetAmount: number;
  targetDate: string;
  currentSavings: number;
  monthlyExpenses: number;
  averageIncome: number;
}

export interface GoalPlanNumbers {
  monthsLeft: number;
  requiredMonthlySavings: number;
  requiredMonthlyIncome: number;
  riskStatus: 'LOW' | 'MEDIUM' | 'HIGH';
}

export function computeGoalPlan(input: GoalPlanInput, now = new Date()): GoalPlanNumbers {
  const target = new Date(input.targetDate);
  const monthsLeft = Math.max(
    1,
    (target.getFullYear() - now.getFullYear()) * 12 + (target.getMonth() - now.getMonth()),
  );
  const remaining = Math.max(0, input.targetAmount - input.currentSavings);
  const requiredMonthlySavings = round2(remaining / monthsLeft);
  const requiredMonthlyIncome = round2(input.monthlyExpenses + requiredMonthlySavings);
  // Share of income the goal needs, after expenses are paid.
  const spare = input.averageIncome - input.monthlyExpenses;
  const riskStatus: GoalPlanNumbers['riskStatus'] =
    remaining === 0
      ? 'LOW'
      : spare <= 0
        ? 'HIGH'
        : requiredMonthlySavings <= spare * 0.5
          ? 'LOW'
          : requiredMonthlySavings <= spare
            ? 'MEDIUM'
            : 'HIGH';
  return { monthsLeft, requiredMonthlySavings, requiredMonthlyIncome, riskStatus };
}

export interface ScenarioNumbers {
  monthlyNet: number;
  baselineMonthlyNet: number;
  projections: { month: string; balance: number }[];
  baselineProjections: { month: string; balance: number }[];
}

const num = (v: unknown): number | undefined =>
  typeof v === 'number' && Number.isFinite(v)
    ? v
    : typeof v === 'string' && v.trim() !== '' && Number.isFinite(Number(v))
      ? Number(v)
      : undefined;

/**
 * Six-month balance projection. Parameters (any may be omitted):
 * currentBalance, monthlyIncome, monthlyExpenses, incomeChange (+/-),
 * expenseChange (+/-) or monthlyCut (a reduction), or a direct monthlyChange.
 */
export function computeScenario(
  parameters: Record<string, unknown>,
  now = new Date(),
  months = 6,
): ScenarioNumbers {
  const balance = num(parameters.currentBalance) ?? 0;
  const income = num(parameters.monthlyIncome) ?? 0;
  const expenses = num(parameters.monthlyExpenses) ?? 0;
  const incomeChange = num(parameters.incomeChange) ?? 0;
  const expenseChange =
    num(parameters.expenseChange) ?? -(num(parameters.monthlyCut) ?? 0);
  const direct = num(parameters.monthlyChange);

  const baselineMonthlyNet = round2(income - expenses);
  const monthlyNet = round2(
    direct !== undefined && income === 0 && expenses === 0
      ? direct
      : income + incomeChange - (expenses + expenseChange),
  );

  const label = (i: number) => {
    const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + i + 1, 1));
    return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
  };
  const project = (net: number) =>
    Array.from({ length: months }, (_, i) => ({
      month: label(i),
      balance: round2(balance + net * (i + 1)),
    }));

  return {
    monthlyNet,
    baselineMonthlyNet,
    projections: project(monthlyNet),
    baselineProjections: project(baselineMonthlyNet),
  };
}

function round2(v: number): number {
  return Math.round(v * 100) / 100;
}
