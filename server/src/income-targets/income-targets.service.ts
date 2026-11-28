import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { InsightsService } from '../insights/insights.service.js';
import {
  CreateIncomeTargetDto,
  UpdateIncomeTargetDto,
} from './dto/income-target.dto.js';

const DAY = 24 * 60 * 60 * 1000;

@Injectable()
export class IncomeTargetsService {
  constructor(
    private prisma: PrismaService,
    private insights: InsightsService,
  ) {}

  findAll(userId: string) {
    return this.prisma.incomeTarget.findMany({
      where: { userId },
      orderBy: { effectiveFrom: 'desc' },
    });
  }

  create(userId: string, dto: CreateIncomeTargetDto) {
    const now = new Date();
    return this.prisma.incomeTarget.create({
      data: {
        userId,
        title: dto.title,
        targetMonthlyIncome: dto.targetMonthlyIncome,
        effectiveFrom: dto.effectiveFrom
          ? new Date(dto.effectiveFrom)
          : new Date(now.getFullYear(), now.getMonth(), 1),
        effectiveTo: dto.effectiveTo ? new Date(dto.effectiveTo) : null,
        reason: dto.reason,
      },
    });
  }

  async update(id: string, userId: string, dto: UpdateIncomeTargetDto) {
    await this.findOwned(id, userId);
    return this.prisma.incomeTarget.update({
      where: { id },
      data: {
        title: dto.title,
        targetMonthlyIncome: dto.targetMonthlyIncome,
        effectiveFrom: dto.effectiveFrom ? new Date(dto.effectiveFrom) : undefined,
        effectiveTo: dto.effectiveTo ? new Date(dto.effectiveTo) : undefined,
        reason: dto.reason,
      },
    });
  }

  async remove(id: string, userId: string) {
    await this.findOwned(id, userId);
    await this.prisma.incomeTarget.delete({ where: { id } });
    return { deleted: true };
  }

  /**
   * The target in effect today and how this month is going against it, in
   * the user's primary currency. Null when no target is active.
   */
  async current(userId: string) {
    const now = new Date();
    const target = await this.prisma.incomeTarget.findFirst({
      where: {
        userId,
        effectiveFrom: { lte: now },
        OR: [{ effectiveTo: null }, { effectiveTo: { gte: now } }],
      },
      orderBy: { effectiveFrom: 'desc' },
    });
    if (!target) return null;

    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    const [user, income] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { primaryCurrency: true },
      }),
      this.prisma.transaction.findMany({
        where: {
          userId,
          type: 'INCOME',
          occurredAt: { gte: monthStart, lt: monthEnd },
          isBalanceSource: false, // reconciliation adjustments aren't income
        },
        select: { amount: true, currency: true },
      }),
    ]);
    const currency = user?.primaryCurrency ?? 'USD';
    const convert = await this.insights.loadConverter(
      income.map((t) => [t.currency, currency] as [string, string]),
    );
    const earned = income.reduce(
      (sum, t) => sum + convert(Number(t.amount), t.currency, currency),
      0,
    );
    const goal = Number(target.targetMonthlyIncome);
    const remaining = Math.max(0, goal - earned);
    const daysLeft = Math.max(
      1,
      Math.ceil((monthEnd.getTime() - now.getTime()) / DAY),
    );
    const daysInMonth = Math.round(
      (monthEnd.getTime() - monthStart.getTime()) / DAY,
    );

    return {
      target,
      currency,
      earnedThisMonth: Number(earned.toFixed(2)),
      remaining: Number(remaining.toFixed(2)),
      percentage: goal > 0 ? Number(((earned / goal) * 100).toFixed(1)) : 0,
      daysLeft,
      neededPerDay: Number((remaining / daysLeft).toFixed(2)),
      // On pace if earnings keep up with the share of the month elapsed.
      onTrack: earned >= goal * (now.getDate() / daysInMonth),
    };
  }

  private async findOwned(id: string, userId: string) {
    const target = await this.prisma.incomeTarget.findUnique({ where: { id } });
    if (!target || target.userId !== userId) {
      throw new NotFoundException('Income target not found');
    }
    return target;
  }
}
