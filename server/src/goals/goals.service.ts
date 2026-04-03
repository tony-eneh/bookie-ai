import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateGoalDto } from './dto/create-goal.dto.js';
import { UpdateGoalDto } from './dto/update-goal.dto.js';
import { CreateContributionDto } from './dto/create-contribution.dto.js';
import type { GoalStatus } from '@prisma/client';

@Injectable()
export class GoalsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateGoalDto) {
    const targetDate = new Date(dto.targetDate);
    const monthlyRequiredAmount = this.calcMonthlyRequired(
      dto.targetAmount,
      0,
      targetDate,
    );

    return this.prisma.goal.create({
      data: {
        userId,
        title: dto.title,
        description: dto.description,
        targetAmount: dto.targetAmount,
        targetCurrency: dto.targetCurrency,
        targetDate,
        priority: dto.priority ?? 'MEDIUM',
        linkedBudgetStrategy: dto.linkedBudgetStrategy,
        monthlyRequiredAmount,
      },
    });
  }

  async findAll(userId: string) {
    const goals = await this.prisma.goal.findMany({
      where: { userId },
      include: { contributions: true },
      orderBy: { createdAt: 'desc' },
    });

    return goals.map((goal) => ({
      ...goal,
      status: this.calculateStatus(goal),
    }));
  }

  async findById(id: string, userId: string) {
    const goal = await this.prisma.goal.findUnique({
      where: { id },
      include: {
        contributions: { orderBy: { contributionDate: 'desc' } },
      },
    });

    if (!goal || goal.userId !== userId) {
      throw new NotFoundException('Goal not found');
    }

    return {
      ...goal,
      status: this.calculateStatus(goal),
    };
  }

  async update(id: string, userId: string, dto: UpdateGoalDto) {
    const existing = await this.findById(id, userId);

    const data: Record<string, unknown> = {};
    if (dto.title !== undefined) data.title = dto.title;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.targetAmount !== undefined) data.targetAmount = dto.targetAmount;
    if (dto.targetCurrency !== undefined)
      data.targetCurrency = dto.targetCurrency;
    if (dto.targetDate !== undefined) data.targetDate = new Date(dto.targetDate);
    if (dto.priority !== undefined) data.priority = dto.priority;
    if (dto.linkedBudgetStrategy !== undefined)
      data.linkedBudgetStrategy = dto.linkedBudgetStrategy;

    const targetAmount = dto.targetAmount ?? Number(existing.targetAmount);
    const targetDate = dto.targetDate
      ? new Date(dto.targetDate)
      : existing.targetDate;

    data.monthlyRequiredAmount = this.calcMonthlyRequired(
      targetAmount,
      Number(existing.currentAmount),
      targetDate,
    );

    const goal = await this.prisma.goal.update({
      where: { id },
      data,
      include: { contributions: true },
    });

    const status = this.calculateStatus(goal);
    if (status !== goal.status) {
      await this.prisma.goal.update({
        where: { id },
        data: { status },
      });
    }

    return { ...goal, status };
  }

  async delete(id: string, userId: string) {
    await this.findById(id, userId);
    return this.prisma.goal.delete({ where: { id } });
  }

  async addContribution(
    goalId: string,
    userId: string,
    dto: CreateContributionDto,
  ) {
    const goal = await this.findById(goalId, userId);

    const contribution = await this.prisma.goalContribution.create({
      data: {
        goalId,
        amount: dto.amount,
        currency: dto.currency,
        contributionDate: dto.contributionDate
          ? new Date(dto.contributionDate)
          : new Date(),
        sourceType: dto.sourceType,
      },
    });

    const newCurrentAmount = Number(goal.currentAmount) + dto.amount;
    const status = this.calculateStatusFromValues(
      Number(goal.targetAmount),
      newCurrentAmount,
      goal.targetDate,
      goal.createdAt,
    );

    await this.prisma.goal.update({
      where: { id: goalId },
      data: {
        currentAmount: newCurrentAmount,
        monthlyRequiredAmount: this.calcMonthlyRequired(
          Number(goal.targetAmount),
          newCurrentAmount,
          goal.targetDate,
        ),
        status,
      },
    });

    return contribution;
  }

  async getProjection(id: string, userId: string) {
    const goal = await this.prisma.goal.findUnique({
      where: { id },
      include: {
        contributions: { orderBy: { contributionDate: 'desc' } },
      },
    });

    if (!goal || goal.userId !== userId) {
      throw new NotFoundException('Goal not found');
    }

    const targetAmount = Number(goal.targetAmount);
    const currentAmount = Number(goal.currentAmount);
    const remaining = targetAmount - currentAmount;
    const targetDate = goal.targetDate;
    const now = new Date();

    // Months remaining to target
    const monthsRemaining = Math.max(
      0,
      (targetDate.getFullYear() - now.getFullYear()) * 12 +
        (targetDate.getMonth() - now.getMonth()),
    );

    const requiredMonthlySavings =
      monthsRemaining > 0 ? remaining / monthsRemaining : remaining;

    // Average monthly expenses for the user (last 3 months)
    const threeMonthsAgo = new Date(now);
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
    const expenses = await this.prisma.transaction.findMany({
      where: {
        userId,
        type: 'EXPENSE',
        occurredAt: { gte: threeMonthsAgo },
      },
    });
    const totalExpenses = expenses.reduce(
      (sum, tx) => sum + Number(tx.amount),
      0,
    );
    const avgMonthlyExpenses = totalExpenses / 3;
    const requiredMonthlyIncome = avgMonthlyExpenses + requiredMonthlySavings;

    // Current pace based on recent contributions (last 3 months)
    const recentContributions = goal.contributions.filter(
      (c) => c.contributionDate >= threeMonthsAgo,
    );
    const totalRecentContributions = recentContributions.reduce(
      (sum, c) => sum + Number(c.amount),
      0,
    );
    const monthsOfContributions = Math.max(
      1,
      Math.min(
        3,
        (now.getTime() - (goal.createdAt?.getTime() ?? now.getTime())) /
          (1000 * 60 * 60 * 24 * 30),
      ),
    );
    const currentPace = totalRecentContributions / monthsOfContributions;

    // Projected completion date
    let projectedCompletionDate: Date | null = null;
    if (currentPace > 0) {
      const monthsToComplete = remaining / currentPace;
      projectedCompletionDate = new Date(now);
      projectedCompletionDate.setMonth(
        projectedCompletionDate.getMonth() + Math.ceil(monthsToComplete),
      );
    }

    // Status determination
    let status: GoalStatus;
    let coaching: string;

    if (currentAmount >= targetAmount) {
      status = 'ACHIEVED';
      coaching =
        'Congratulations! You have reached your goal. Consider setting a new target.';
    } else if (
      projectedCompletionDate &&
      projectedCompletionDate <= targetDate
    ) {
      status = 'ON_TRACK';
      coaching = `Great pace! At your current rate of ${currentPace.toFixed(0)}/month, you'll reach your goal on time.`;
    } else if (projectedCompletionDate) {
      const overshootMonths =
        (projectedCompletionDate.getTime() - targetDate.getTime()) /
        (1000 * 60 * 60 * 24 * 30);
      if (overshootMonths <= monthsRemaining * 0.2) {
        status = 'AT_RISK';
        coaching = `You're close but may miss your target by about ${Math.ceil(overshootMonths)} month(s). Try increasing monthly contributions to ${requiredMonthlySavings.toFixed(0)}.`;
      } else {
        status = 'OFF_TRACK';
        coaching = `At your current pace, you'll miss your target date. You need to save ${requiredMonthlySavings.toFixed(0)}/month but are averaging ${currentPace.toFixed(0)}/month.`;
      }
    } else {
      status = 'OFF_TRACK';
      coaching =
        'No contributions recorded yet. Start saving to make progress toward your goal.';
    }

    return {
      monthsRemaining,
      requiredMonthlySavings: Number(requiredMonthlySavings.toFixed(2)),
      requiredMonthlyIncome: Number(requiredMonthlyIncome.toFixed(2)),
      currentPace: Number(currentPace.toFixed(2)),
      projectedCompletionDate,
      status,
      coaching,
    };
  }

  calculateStatus(goal: {
    targetAmount: unknown;
    currentAmount: unknown;
    targetDate: Date;
    createdAt: Date;
  }): GoalStatus {
    return this.calculateStatusFromValues(
      Number(goal.targetAmount),
      Number(goal.currentAmount),
      goal.targetDate,
      goal.createdAt,
    );
  }

  private calculateStatusFromValues(
    targetAmount: number,
    currentAmount: number,
    targetDate: Date,
    createdAt: Date,
  ): GoalStatus {
    if (currentAmount >= targetAmount) return 'ACHIEVED';

    const now = new Date();
    const totalDuration = targetDate.getTime() - createdAt.getTime();
    const timeElapsed = now.getTime() - createdAt.getTime();

    if (totalDuration <= 0 || now >= targetDate) return 'OFF_TRACK';

    const progressRatio = currentAmount / targetAmount;
    const timeElapsedRatio = timeElapsed / totalDuration;

    if (progressRatio >= timeElapsedRatio * 0.8) return 'ON_TRACK';
    if (progressRatio >= timeElapsedRatio * 0.6) return 'AT_RISK';
    return 'OFF_TRACK';
  }

  private calcMonthlyRequired(
    targetAmount: number,
    currentAmount: number,
    targetDate: Date,
  ): number {
    const now = new Date();
    const months = Math.max(
      1,
      (targetDate.getFullYear() - now.getFullYear()) * 12 +
        (targetDate.getMonth() - now.getMonth()),
    );
    const remaining = targetAmount - currentAmount;
    return remaining > 0 ? Number((remaining / months).toFixed(4)) : 0;
  }
}
