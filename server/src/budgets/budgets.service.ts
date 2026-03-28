import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateBudgetDto } from './dto/create-budget.dto.js';
import { UpdateBudgetDto } from './dto/update-budget.dto.js';

@Injectable()
export class BudgetsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateBudgetDto) {
    return this.prisma.budget.create({
      data: {
        userId,
        name: dto.name,
        categoryId: dto.categoryId,
        periodType: dto.periodType,
        amount: dto.amount,
        currency: dto.currency,
        startDate: new Date(dto.startDate),
      },
      include: { category: true },
    });
  }

  async findAll(userId: string) {
    const budgets = await this.prisma.budget.findMany({
      where: { userId },
      include: { category: true },
      orderBy: { createdAt: 'desc' },
    });

    return Promise.all(
      budgets.map(async (budget) => {
        const progress = await this.calculateProgress(budget);
        return { ...budget, progress };
      }),
    );
  }

  async findById(id: string, userId: string) {
    const budget = await this.prisma.budget.findUnique({
      where: { id },
      include: { category: true },
    });

    if (!budget || budget.userId !== userId) {
      throw new NotFoundException('Budget not found');
    }

    const progress = await this.calculateProgress(budget);
    return { ...budget, progress };
  }

  async update(id: string, userId: string, dto: UpdateBudgetDto) {
    await this.findById(id, userId);

    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.categoryId !== undefined) data.categoryId = dto.categoryId;
    if (dto.periodType !== undefined) data.periodType = dto.periodType;
    if (dto.amount !== undefined) data.amount = dto.amount;
    if (dto.currency !== undefined) data.currency = dto.currency;
    if (dto.startDate !== undefined) data.startDate = new Date(dto.startDate);

    const budget = await this.prisma.budget.update({
      where: { id },
      data,
      include: { category: true },
    });

    const progress = await this.calculateProgress(budget);
    return { ...budget, progress };
  }

  async delete(id: string, userId: string) {
    await this.findById(id, userId);
    return this.prisma.budget.delete({ where: { id } });
  }

  async getProgress(id: string, userId: string) {
    const budget = await this.prisma.budget.findUnique({
      where: { id },
      include: { category: true },
    });

    if (!budget || budget.userId !== userId) {
      throw new NotFoundException('Budget not found');
    }

    return this.calculateProgress(budget);
  }

  private async calculateProgress(budget: {
    id: string;
    userId: string;
    categoryId: string | null;
    periodType: string;
    amount: unknown;
    currency: string;
  }) {
    const { periodStart, periodEnd } = this.getCurrentPeriod(budget.periodType);
    const budgetAmount = Number(budget.amount);

    const where: Record<string, unknown> = {
      userId: budget.userId,
      type: 'EXPENSE',
      occurredAt: { gte: periodStart, lte: periodEnd },
    };

    if (budget.categoryId) {
      where.categoryId = budget.categoryId;
    }

    const transactions = await this.prisma.transaction.findMany({ where });

    const amountUsed = transactions.reduce(
      (sum, tx) => sum + Number(tx.amount),
      0,
    );

    const amountRemaining = Math.max(0, budgetAmount - amountUsed);
    const percentageUsed =
      budgetAmount > 0 ? (amountUsed / budgetAmount) * 100 : 0;
    const isOverspent = amountUsed > budgetAmount;

    // Project overspend based on daily spending rate
    const now = new Date();
    const daysElapsed = Math.max(
      1,
      Math.ceil(
        (now.getTime() - periodStart.getTime()) / (1000 * 60 * 60 * 24),
      ),
    );
    const totalDays = Math.ceil(
      (periodEnd.getTime() - periodStart.getTime()) / (1000 * 60 * 60 * 24),
    );
    const dailyRate = amountUsed / daysElapsed;
    const projectedTotal = dailyRate * totalDays;
    const projectedOverspend = Math.max(0, projectedTotal - budgetAmount);

    return {
      amountUsed: Number(amountUsed.toFixed(2)),
      amountRemaining: Number(amountRemaining.toFixed(2)),
      percentageUsed: Number(percentageUsed.toFixed(1)),
      isOverspent,
      projectedOverspend: Number(projectedOverspend.toFixed(2)),
      periodStart,
      periodEnd,
    };
  }

  private getCurrentPeriod(periodType: string): {
    periodStart: Date;
    periodEnd: Date;
  } {
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

    // MONTHLY
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
