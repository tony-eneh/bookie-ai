import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';
import { UpdateTransactionDto } from './dto/update-transaction.dto.js';
import { TransactionFilterDto } from './dto/transaction-filter.dto.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class TransactionsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateTransactionDto) {
    const needsClarification =
      (dto.parseConfidence !== undefined && dto.parseConfidence < 0.7) ||
      (dto.categoryConfidence !== undefined && dto.categoryConfidence < 0.7);

    return this.prisma.$transaction(async (tx) => {
      const account = await tx.account.findUnique({
        where: { id: dto.accountId },
      });

      if (!account || account.userId !== userId) {
        throw new NotFoundException('Account not found');
      }

      const balanceDelta = this.getBalanceDelta(dto.type, dto.amount);
      const updatedAccount = await tx.account.update({
        where: { id: dto.accountId },
        data: {
          currentBalance: {
            increment: new Prisma.Decimal(balanceDelta.toFixed(4)),
          },
        },
      });

      return tx.transaction.create({
        data: {
          userId,
          accountId: dto.accountId,
          type: dto.type,
          amount: dto.amount,
          currency: dto.currency,
          occurredAt: new Date(dto.occurredAt),
          description: dto.description,
          merchantName: dto.merchantName,
          counterparty: dto.counterparty,
          categoryId: dto.categoryId,
          subcategory: dto.subcategory,
          sourceType: dto.sourceType,
          rawContent: dto.rawContent,
          note: dto.note,
          parseConfidence: dto.parseConfidence ?? 1.0,
          categoryConfidence: dto.categoryConfidence ?? 1.0,
          needsClarification,
          clarificationStatus: needsClarification ? 'PENDING' : 'NONE',
          balanceAfterTransaction: updatedAccount.currentBalance,
        },
      });
    });
  }

  async findAll(userId: string, filters: TransactionFilterDto) {
    const where: Prisma.TransactionWhereInput = { userId };

    if (filters.accountId) where.accountId = filters.accountId;
    if (filters.type) where.type = filters.type;
    if (filters.categoryId) where.categoryId = filters.categoryId;
    if (filters.sourceType) where.sourceType = filters.sourceType;

    if (filters.startDate || filters.endDate) {
      where.occurredAt = {};
      if (filters.startDate)
        where.occurredAt.gte = new Date(filters.startDate);
      if (filters.endDate) where.occurredAt.lte = new Date(filters.endDate);
    }

    if (filters.minAmount !== undefined || filters.maxAmount !== undefined) {
      where.amount = {};
      if (filters.minAmount !== undefined)
        where.amount.gte = filters.minAmount;
      if (filters.maxAmount !== undefined)
        where.amount.lte = filters.maxAmount;
    }

    if (filters.search) {
      where.OR = [
        { description: { contains: filters.search, mode: 'insensitive' } },
        { merchantName: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const skip = (filters.page - 1) * filters.limit;

    const [transactions, total] = await Promise.all([
      this.prisma.transaction.findMany({
        where,
        include: { category: true, account: true },
        orderBy: { occurredAt: 'desc' },
        skip,
        take: filters.limit,
      }),
      this.prisma.transaction.count({ where }),
    ]);

    return {
      data: transactions,
      meta: {
        page: filters.page,
        limit: filters.limit,
        total,
        totalPages: Math.ceil(total / filters.limit),
      },
    };
  }

  async findById(id: string, userId: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: { category: true, account: true },
    });

    if (!transaction || transaction.userId !== userId) {
      throw new NotFoundException('Transaction not found');
    }

    return transaction;
  }

  async update(id: string, userId: string, dto: UpdateTransactionDto) {
    return this.prisma.$transaction(async (tx) => {
      const existing = await tx.transaction.findUnique({
        where: { id },
        include: { category: true, account: true },
      });

      if (!existing || existing.userId !== userId) {
        throw new NotFoundException('Transaction not found');
      }

      const oldAmount = Number(existing.amount);
      const newAmount = dto.amount ?? oldAmount;
      const oldDelta = this.getBalanceDelta(existing.type, oldAmount);
      const newType = dto.type ?? existing.type;
      const newDelta = this.getBalanceDelta(newType, newAmount);
      const balanceAdjustment = newDelta - oldDelta;

      let balanceAfterTransaction = existing.balanceAfterTransaction;
      if (Math.abs(balanceAdjustment) > 0.001) {
        const updatedAccount = await tx.account.update({
          where: { id: existing.accountId },
          data: {
            currentBalance: {
              increment: new Prisma.Decimal(balanceAdjustment.toFixed(4)),
            },
          },
        });
        balanceAfterTransaction = updatedAccount.currentBalance;
      }

      const data: Prisma.TransactionUncheckedUpdateInput = {};
      if (dto.type !== undefined) data.type = dto.type;
      if (dto.amount !== undefined) data.amount = dto.amount;
      if (dto.currency !== undefined) data.currency = dto.currency;
      if (dto.occurredAt !== undefined) data.occurredAt = new Date(dto.occurredAt);
      if (dto.description !== undefined) data.description = dto.description;
      if (dto.merchantName !== undefined) data.merchantName = dto.merchantName;
      if (dto.counterparty !== undefined) data.counterparty = dto.counterparty;
      if (dto.categoryId !== undefined) data.categoryId = dto.categoryId;
      if (dto.subcategory !== undefined) data.subcategory = dto.subcategory;
      if (dto.sourceType !== undefined) data.sourceType = dto.sourceType;
      if (dto.rawContent !== undefined) data.rawContent = dto.rawContent;
      if (dto.note !== undefined) data.note = dto.note;
      if (dto.parseConfidence !== undefined) data.parseConfidence = dto.parseConfidence;
      if (dto.categoryConfidence !== undefined) {
        data.categoryConfidence = dto.categoryConfidence;
      }
      if (dto.amount !== undefined || dto.type !== undefined) {
        data.balanceAfterTransaction = balanceAfterTransaction;
      }

      return tx.transaction.update({
        where: { id },
        data,
        include: { category: true, account: true },
      });
    });
  }

  async delete(id: string, userId: string) {
    return this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.findUnique({ where: { id } });

      if (!transaction || transaction.userId !== userId) {
        throw new NotFoundException('Transaction not found');
      }

      const balanceAdjustment = -this.getBalanceDelta(
        transaction.type,
        Number(transaction.amount),
      );

      await tx.account.update({
        where: { id: transaction.accountId },
        data: {
          currentBalance: {
            increment: new Prisma.Decimal(balanceAdjustment.toFixed(4)),
          },
        },
      });

      return tx.transaction.delete({ where: { id } });
    });
  }

  async getMonthlyStats(userId: string, month: number, year: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);

    const transactions = await this.prisma.transaction.findMany({
      where: {
        userId,
        occurredAt: { gte: startDate, lte: endDate },
      },
    });

    let totalIncome = 0;
    let totalExpense = 0;

    for (const tx of transactions) {
      const amount = Number(tx.amount);
      if (tx.type === 'INCOME') {
        totalIncome += amount;
      } else if (tx.type === 'EXPENSE') {
        totalExpense += amount;
      }
    }

    return {
      month,
      year,
      totalIncome: Number(totalIncome.toFixed(2)),
      totalExpense: Number(totalExpense.toFixed(2)),
      netCashFlow: Number((totalIncome - totalExpense).toFixed(2)),
      transactionCount: transactions.length,
    };
  }

  async getCategoryBreakdown(userId: string, month: number, year: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999);

    const transactions = await this.prisma.transaction.findMany({
      where: {
        userId,
        type: 'EXPENSE',
        occurredAt: { gte: startDate, lte: endDate },
      },
      include: { category: true },
    });

    const breakdown = new Map<
      string,
      { categoryId: string | null; categoryName: string; icon: string; total: number; count: number }
    >();

    for (const tx of transactions) {
      const key = tx.categoryId ?? 'uncategorized';
      const existing = breakdown.get(key);

      if (existing) {
        existing.total += Number(tx.amount);
        existing.count += 1;
      } else {
        breakdown.set(key, {
          categoryId: tx.categoryId,
          categoryName: tx.category?.name ?? 'Uncategorized',
          icon: tx.category?.icon ?? '📦',
          total: Number(tx.amount),
          count: 1,
        });
      }
    }

    const categories = Array.from(breakdown.values())
      .map((b) => ({
        ...b,
        total: Number(b.total.toFixed(2)),
      }))
      .sort((a, b) => b.total - a.total);

    const grandTotal = categories.reduce((sum, c) => sum + c.total, 0);

    return {
      month,
      year,
      categories: categories.map((c) => ({
        ...c,
        percentage:
          grandTotal > 0
            ? Number(((c.total / grandTotal) * 100).toFixed(1))
            : 0,
      })),
      grandTotal: Number(grandTotal.toFixed(2)),
    };
  }

  private getBalanceDelta(type: string, amount: number) {
    if (type === 'INCOME') {
      return amount;
    }

    return -amount;
  }
}
