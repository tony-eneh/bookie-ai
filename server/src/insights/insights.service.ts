import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { AiService } from '../ai/ai.service.js';

@Injectable()
export class InsightsService {
  constructor(
    private prisma: PrismaService,
    private aiService: AiService,
  ) {}

  async getDashboard(userId: string) {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
      23,
      59,
      59,
      999,
    );

    // Run all queries in parallel
    const [
      incomeAgg,
      expenseAgg,
      budgets,
      topCategories,
      pendingClarifications,
      goals,
      recentTransactions,
    ] = await Promise.all([
      this.prisma.transaction.findMany({
        where: {
          userId,
          type: 'INCOME',
          occurredAt: { gte: monthStart, lte: monthEnd },
        },
      }),
      this.prisma.transaction.findMany({
        where: {
          userId,
          type: 'EXPENSE',
          occurredAt: { gte: monthStart, lte: monthEnd },
        },
      }),
      this.prisma.budget.findMany({
        where: { userId, isActive: true },
        include: { category: true },
      }),
      this.prisma.transaction.findMany({
        where: {
          userId,
          type: 'EXPENSE',
          occurredAt: { gte: monthStart, lte: monthEnd },
        },
        include: { category: true },
      }),
      this.prisma.clarification.count({
        where: { userId, status: 'PENDING' },
      }),
      this.prisma.goal.findMany({
        where: { userId },
        orderBy: { targetDate: 'asc' },
      }),
      this.prisma.transaction.findMany({
        where: { userId },
        include: { category: true, account: true },
        orderBy: { occurredAt: 'desc' },
        take: 10,
      }),
    ]);

    const totalIncome = incomeAgg.reduce(
      (sum, tx) => sum + Number(tx.amount),
      0,
    );
    const totalExpenses = expenseAgg.reduce(
      (sum, tx) => sum + Number(tx.amount),
      0,
    );
    const netCashFlow = totalIncome - totalExpenses;

    // Budget progress
    const budgetProgress = await Promise.all(
      budgets.map(async (budget) => {
        const { periodStart, periodEnd } = this.getCurrentPeriod(
          budget.periodType,
        );
        const budgetAmount = Number(budget.amount);
        const where: Record<string, unknown> = {
          userId,
          type: 'EXPENSE',
          occurredAt: { gte: periodStart, lte: periodEnd },
        };
        if (budget.categoryId) where.categoryId = budget.categoryId;

        const txs = await this.prisma.transaction.findMany({ where });
        const spent = txs.reduce((sum, tx) => sum + Number(tx.amount), 0);

        return {
          budgetId: budget.id,
          name: budget.name,
          categoryName: budget.category?.name ?? 'All',
          budgetAmount: Number(budgetAmount.toFixed(2)),
          spent: Number(spent.toFixed(2)),
          remaining: Number(Math.max(0, budgetAmount - spent).toFixed(2)),
          percentageUsed:
            budgetAmount > 0
              ? Number(((spent / budgetAmount) * 100).toFixed(1))
              : 0,
          isOverspent: spent > budgetAmount,
        };
      }),
    );

    // Top 5 expense categories
    const categoryMap = new Map<
      string,
      { name: string; icon: string; total: number }
    >();
    for (const tx of topCategories) {
      const key = tx.categoryId ?? 'uncategorized';
      const existing = categoryMap.get(key);
      if (existing) {
        existing.total += Number(tx.amount);
      } else {
        categoryMap.set(key, {
          name: tx.category?.name ?? 'Uncategorized',
          icon: tx.category?.icon ?? '📦',
          total: Number(tx.amount),
        });
      }
    }
    const topCats = Array.from(categoryMap.values())
      .map((c) => ({ ...c, total: Number(c.total.toFixed(2)) }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 5);

    // Goal progress
    const goalProgress = goals.map((goal) => {
      const target = Number(goal.targetAmount);
      const current = Number(goal.currentAmount);
      return {
        goalId: goal.id,
        title: goal.title,
        targetAmount: target,
        currentAmount: current,
        percentage: target > 0 ? Number(((current / target) * 100).toFixed(1)) : 0,
        status: goal.status,
        targetDate: goal.targetDate,
      };
    });

    // Smart insights
    const smartInsights = this.generateSmartInsights(
      totalIncome,
      totalExpenses,
      budgetProgress,
      goalProgress,
    );

    return {
      totalIncome: Number(totalIncome.toFixed(2)),
      totalExpenses: Number(totalExpenses.toFixed(2)),
      netCashFlow: Number(netCashFlow.toFixed(2)),
      budgetProgress,
      topCategories: topCats,
      pendingClarifications,
      goalProgress,
      recentTransactions,
      smartInsights,
    };
  }

  async getWeeklySummary(userId: string) {
    const { periodStart, periodEnd } = this.getCurrentPeriod('WEEKLY');

    // Previous week range
    const prevStart = new Date(periodStart);
    prevStart.setDate(prevStart.getDate() - 7);
    const prevEnd = new Date(periodStart);
    prevEnd.setMilliseconds(-1);

    const [currentTxs, prevTxs, pendingClarifications, goals] =
      await Promise.all([
        this.prisma.transaction.findMany({
          where: {
            userId,
            occurredAt: { gte: periodStart, lte: periodEnd },
          },
          include: { category: true },
        }),
        this.prisma.transaction.findMany({
          where: {
            userId,
            occurredAt: { gte: prevStart, lte: prevEnd },
          },
        }),
        this.prisma.clarification.count({
          where: { userId, status: 'PENDING' },
        }),
        this.prisma.goal.findMany({ where: { userId } }),
      ]);

    const income = currentTxs
      .filter((tx) => tx.type === 'INCOME')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const expenses = currentTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const net = income - expenses;

    const prevIncome = prevTxs
      .filter((tx) => tx.type === 'INCOME')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const prevExpenses = prevTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);

    // Top category
    const catMap = new Map<string, { name: string; total: number }>();
    for (const tx of currentTxs.filter((t) => t.type === 'EXPENSE')) {
      const key = tx.categoryId ?? 'uncategorized';
      const existing = catMap.get(key);
      if (existing) {
        existing.total += Number(tx.amount);
      } else {
        catMap.set(key, {
          name: tx.category?.name ?? 'Uncategorized',
          total: Number(tx.amount),
        });
      }
    }
    const topCategory = Array.from(catMap.values()).sort(
      (a, b) => b.total - a.total,
    )[0] ?? { name: 'N/A', total: 0 };

    const goalProgress = goals.map((g) => ({
      title: g.title,
      status: g.status,
      percentage:
        Number(g.targetAmount) > 0
          ? Number(
              ((Number(g.currentAmount) / Number(g.targetAmount)) * 100).toFixed(
                1,
              ),
            )
          : 0,
    }));

    const summary = await this.aiService.generateSummary('weekly', {
      totalIncome: income,
      totalExpenses: expenses,
    });

    return {
      periodStart,
      periodEnd,
      income: Number(income.toFixed(2)),
      expenses: Number(expenses.toFixed(2)),
      net: Number(net.toFixed(2)),
      topCategory: {
        name: topCategory.name,
        amount: Number(topCategory.total.toFixed(2)),
      },
      goalProgress,
      pendingClarifications,
      vsPreviousWeek: {
        incomeChange: Number((income - prevIncome).toFixed(2)),
        expenseChange: Number((expenses - prevExpenses).toFixed(2)),
        incomeChangePercent:
          prevIncome > 0
            ? Number((((income - prevIncome) / prevIncome) * 100).toFixed(1))
            : 0,
        expenseChangePercent:
          prevExpenses > 0
            ? Number(
                (((expenses - prevExpenses) / prevExpenses) * 100).toFixed(1),
              )
            : 0,
      },
      aiSummary: summary,
    };
  }

  async getMonthlySummary(userId: string, month?: number, year?: number) {
    const now = new Date();
    const m = month ?? now.getMonth() + 1;
    const y = year ?? now.getFullYear();

    const monthStart = new Date(y, m - 1, 1);
    const monthEnd = new Date(y, m, 0, 23, 59, 59, 999);

    // Previous month
    const prevMonthStart = new Date(y, m - 2, 1);
    const prevMonthEnd = new Date(y, m - 1, 0, 23, 59, 59, 999);

    const [currentTxs, prevTxs, goals] = await Promise.all([
      this.prisma.transaction.findMany({
        where: {
          userId,
          occurredAt: { gte: monthStart, lte: monthEnd },
        },
        include: { category: true },
      }),
      this.prisma.transaction.findMany({
        where: {
          userId,
          occurredAt: { gte: prevMonthStart, lte: prevMonthEnd },
        },
      }),
      this.prisma.goal.findMany({ where: { userId } }),
    ]);

    const income = currentTxs
      .filter((tx) => tx.type === 'INCOME')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const expenses = currentTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const net = income - expenses;
    const savingsRate = income > 0 ? (net / income) * 100 : 0;

    const prevIncome = prevTxs
      .filter((tx) => tx.type === 'INCOME')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const prevExpenses = prevTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);

    // Category breakdown
    const catMap = new Map<
      string,
      { name: string; icon: string; total: number; count: number }
    >();
    for (const tx of currentTxs.filter((t) => t.type === 'EXPENSE')) {
      const key = tx.categoryId ?? 'uncategorized';
      const existing = catMap.get(key);
      if (existing) {
        existing.total += Number(tx.amount);
        existing.count += 1;
      } else {
        catMap.set(key, {
          name: tx.category?.name ?? 'Uncategorized',
          icon: tx.category?.icon ?? '📦',
          total: Number(tx.amount),
          count: 1,
        });
      }
    }
    const categories = Array.from(catMap.values())
      .map((c) => ({
        ...c,
        total: Number(c.total.toFixed(2)),
        percentage:
          expenses > 0
            ? Number(((c.total / expenses) * 100).toFixed(1))
            : 0,
      }))
      .sort((a, b) => b.total - a.total);

    const summary = await this.aiService.generateSummary('monthly', {
      totalIncome: income,
      totalExpenses: expenses,
    });

    return {
      month: m,
      year: y,
      periodStart: monthStart,
      periodEnd: monthEnd,
      income: Number(income.toFixed(2)),
      expenses: Number(expenses.toFixed(2)),
      net: Number(net.toFixed(2)),
      savingsRate: Number(savingsRate.toFixed(1)),
      categories,
      goalProgress: goals.map((g) => ({
        title: g.title,
        status: g.status,
        percentage:
          Number(g.targetAmount) > 0
            ? Number(
                (
                  (Number(g.currentAmount) / Number(g.targetAmount)) *
                  100
                ).toFixed(1),
              )
            : 0,
      })),
      trends: {
        incomeChange: Number((income - prevIncome).toFixed(2)),
        expenseChange: Number((expenses - prevExpenses).toFixed(2)),
        incomeChangePercent:
          prevIncome > 0
            ? Number((((income - prevIncome) / prevIncome) * 100).toFixed(1))
            : 0,
        expenseChangePercent:
          prevExpenses > 0
            ? Number(
                (((expenses - prevExpenses) / prevExpenses) * 100).toFixed(1),
              )
            : 0,
      },
      aiSummary: summary,
    };
  }

  async generateInsights(userId: string) {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
      23,
      59,
      59,
      999,
    );

    const prevMonthStart = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const prevMonthEnd = new Date(
      now.getFullYear(),
      now.getMonth(),
      0,
      23,
      59,
      59,
      999,
    );

    const [currentTxs, prevTxs, budgets, goals] = await Promise.all([
      this.prisma.transaction.findMany({
        where: {
          userId,
          occurredAt: { gte: monthStart, lte: monthEnd },
        },
        include: { category: true },
      }),
      this.prisma.transaction.findMany({
        where: {
          userId,
          occurredAt: { gte: prevMonthStart, lte: prevMonthEnd },
        },
      }),
      this.prisma.budget.findMany({
        where: { userId, isActive: true },
      }),
      this.prisma.goal.findMany({ where: { userId } }),
    ]);

    const currentExpenses = currentTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const prevExpenses = prevTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);

    const insights: {
      insightType: string;
      title: string;
      body: string;
      severity: 'INFO' | 'WARNING' | 'CRITICAL';
    }[] = [];

    // Spending trend
    if (prevExpenses > 0) {
      const change = ((currentExpenses - prevExpenses) / prevExpenses) * 100;
      if (change > 20) {
        insights.push({
          insightType: 'spending_trend',
          title: 'Spending Up Significantly',
          body: `Your spending is up ${change.toFixed(0)}% compared to last month. Review your expenses to stay on track.`,
          severity: 'WARNING',
        });
      } else if (change < -10) {
        insights.push({
          insightType: 'spending_trend',
          title: 'Great Job Reducing Spending!',
          body: `Your spending decreased by ${Math.abs(change).toFixed(0)}% compared to last month. Keep it up!`,
          severity: 'INFO',
        });
      }
    }

    // Budget alerts
    for (const budget of budgets) {
      const budgetAmount = Number(budget.amount);
      const { periodStart, periodEnd } = this.getCurrentPeriod(
        budget.periodType,
      );
      const where: Record<string, unknown> = {
        userId,
        type: 'EXPENSE',
        occurredAt: { gte: periodStart, lte: periodEnd },
      };
      if (budget.categoryId) where.categoryId = budget.categoryId;
      const budgetTxs = await this.prisma.transaction.findMany({ where });
      const spent = budgetTxs.reduce(
        (sum, tx) => sum + Number(tx.amount),
        0,
      );
      const pct = budgetAmount > 0 ? (spent / budgetAmount) * 100 : 0;

      if (pct > 100) {
        insights.push({
          insightType: 'budget_overspend',
          title: `Budget "${budget.name}" Exceeded`,
          body: `You've spent ${pct.toFixed(0)}% of your "${budget.name}" budget. Consider adjusting spending.`,
          severity: 'CRITICAL',
        });
      } else if (pct > 80) {
        insights.push({
          insightType: 'budget_warning',
          title: `Budget "${budget.name}" Nearly Used`,
          body: `You've used ${pct.toFixed(0)}% of your "${budget.name}" budget with time remaining in the period.`,
          severity: 'WARNING',
        });
      }
    }

    // Goal status
    for (const goal of goals) {
      if (goal.status === 'OFF_TRACK') {
        insights.push({
          insightType: 'goal_risk',
          title: `Goal "${goal.title}" Off Track`,
          body: `Your goal "${goal.title}" is falling behind schedule. Consider increasing contributions.`,
          severity: 'WARNING',
        });
      } else if (goal.status === 'ACHIEVED') {
        insights.push({
          insightType: 'goal_achieved',
          title: `Goal "${goal.title}" Achieved! 🎉`,
          body: `Congratulations! You've reached your goal "${goal.title}". Consider setting a new one.`,
          severity: 'INFO',
        });
      }
    }

    // Save insights to database
    const created = await Promise.all(
      insights.map((insight) =>
        this.prisma.insight.create({
          data: {
            userId,
            insightType: insight.insightType,
            title: insight.title,
            body: insight.body,
            severity: insight.severity,
            periodStart: monthStart,
            periodEnd: monthEnd,
          },
        }),
      ),
    );

    return created;
  }

  private generateSmartInsights(
    totalIncome: number,
    totalExpenses: number,
    budgetProgress: { name: string; percentageUsed: number; isOverspent: boolean }[],
    goalProgress: { title: string; status: string; percentage: number }[],
  ) {
    const insights: { type: string; message: string; severity: string }[] = [];

    const net = totalIncome - totalExpenses;
    if (net > 0) {
      const savingsRate = ((net / totalIncome) * 100).toFixed(1);
      insights.push({
        type: 'savings',
        message: `You're saving ${savingsRate}% of your income this month. ${Number(savingsRate) >= 20 ? 'Excellent!' : 'Try to aim for 20%.'}`,
        severity: 'INFO',
      });
    } else if (totalIncome > 0) {
      insights.push({
        type: 'deficit',
        message:
          'You are spending more than you earn this month. Review your expenses.',
        severity: 'WARNING',
      });
    }

    const overspentBudgets = budgetProgress.filter((b) => b.isOverspent);
    if (overspentBudgets.length > 0) {
      insights.push({
        type: 'budget',
        message: `${overspentBudgets.length} budget(s) exceeded: ${overspentBudgets.map((b) => b.name).join(', ')}.`,
        severity: 'WARNING',
      });
    }

    const atRiskGoals = goalProgress.filter(
      (g) => g.status === 'OFF_TRACK' || g.status === 'AT_RISK',
    );
    if (atRiskGoals.length > 0) {
      insights.push({
        type: 'goals',
        message: `${atRiskGoals.length} goal(s) need attention: ${atRiskGoals.map((g) => g.title).join(', ')}.`,
        severity: 'WARNING',
      });
    }

    const achievedGoals = goalProgress.filter(
      (g) => g.status === 'ACHIEVED',
    );
    if (achievedGoals.length > 0) {
      insights.push({
        type: 'achievement',
        message: `🎉 Congratulations! You achieved ${achievedGoals.length} goal(s): ${achievedGoals.map((g) => g.title).join(', ')}.`,
        severity: 'INFO',
      });
    }

    if (insights.length === 0) {
      insights.push({
        type: 'general',
        message:
          'Your finances look stable. Keep tracking your transactions for better insights!',
        severity: 'INFO',
      });
    }

    return insights;
  }

  private getCurrentPeriod(periodType: string) {
    const now = new Date();

    if (periodType === 'WEEKLY') {
      const day = now.getDay();
      const diffToMonday = day === 0 ? -6 : 1 - day;
      const periodStart = new Date(now);
      periodStart.setDate(now.getDate() + diffToMonday);
      periodStart.setHours(0, 0, 0, 0);

      const periodEnd = new Date(periodStart);
      periodEnd.setDate(periodStart.getDate() + 6);
      periodEnd.setHours(23, 59, 59, 999);

      return { periodStart, periodEnd };
    }

    const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const periodEnd = new Date(
      now.getFullYear(),
      now.getMonth() + 1,
      0,
      23,
      59,
      59,
      999,
    );

    return { periodStart, periodEnd };
  }
}
