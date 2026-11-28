import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service.js';
import { balanceDelta } from '../common/balance.js';
import { FxRatesService } from '../fx-rates/fx-rates.service.js';
import { CreateTransferDto } from './dto/create-transfer.dto.js';
import { MerchantAliasService } from '../learning/merchant-alias.service.js';
import { RecurringService } from '../learning/recurring.service.js';
import { NotificationTriggersService } from '../notifications/notification-triggers.service.js';
import { CreateTransactionDto } from './dto/create-transaction.dto.js';
import { UpdateTransactionDto } from './dto/update-transaction.dto.js';
import { TransactionFilterDto } from './dto/transaction-filter.dto.js';
import { Prisma } from '@prisma/client';

@Injectable()
export class TransactionsService {
  constructor(
    private prisma: PrismaService,
    private aliases: MerchantAliasService,
    private recurring: RecurringService,
    private triggers: NotificationTriggersService,
    private fxRates: FxRatesService,
  ) {}

  /**
   * Moves money between two of the user's accounts: an outgoing TRANSFER
   * leg on the source and an incoming one on the destination, linked by
   * transferPairId. Neither counts as income or spending.
   */
  async createTransfer(userId: string, dto: CreateTransferDto) {
    if (dto.fromAccountId === dto.toAccountId) {
      throw new BadRequestException('Choose two different accounts');
    }
    const [from, to] = await Promise.all([
      this.prisma.account.findUnique({ where: { id: dto.fromAccountId } }),
      this.prisma.account.findUnique({ where: { id: dto.toAccountId } }),
    ]);
    if (!from || from.userId !== userId || !to || to.userId !== userId) {
      throw new NotFoundException('Account not found');
    }

    let received = dto.receivedAmount;
    let rate = 1;
    if (received === undefined) {
      rate = from.currency === to.currency
        ? 1
        : await this.fxRates.getRate(from.currency, to.currency);
      received = Math.round(dto.amount * rate * 100) / 100;
    } else if (from.currency !== to.currency) {
      rate = received / dto.amount;
    }

    const occurredAt = dto.occurredAt ? new Date(dto.occurredAt) : new Date();
    const description = dto.description?.trim() || `Transfer to ${to.name}`;
    const outId = randomUUID();
    const inId = randomUUID();
    const category = await this.prisma.category.findFirst({
      where: { isDefault: true, type: 'TRANSFER', name: 'Internal Transfer' },
      select: { id: true },
    });

    return this.prisma.$transaction(async (tx) => {
      const fromAfter = await tx.account.update({
        where: { id: from.id },
        data: { currentBalance: { decrement: new Prisma.Decimal(dto.amount.toFixed(4)) } },
      });
      const toAfter = await tx.account.update({
        where: { id: to.id },
        data: { currentBalance: { increment: new Prisma.Decimal(received.toFixed(4)) } },
      });
      const common = {
        userId,
        type: 'TRANSFER' as const,
        occurredAt,
        categoryId: category?.id,
        sourceType: 'MANUAL' as const,
        parseConfidence: 1,
        categoryConfidence: 1,
      };
      const outgoing = await tx.transaction.create({
        data: {
          ...common,
          id: outId,
          accountId: from.id,
          amount: dto.amount,
          currency: from.currency,
          description,
          transferAccountId: to.id,
          transferPairId: inId,
          transferIn: false,
          balanceAfterTransaction: fromAfter.currentBalance,
        },
        include: { category: true, account: true, transferAccount: true },
      });
      const incoming = await tx.transaction.create({
        data: {
          ...common,
          id: inId,
          accountId: to.id,
          amount: received,
          currency: to.currency,
          description: dto.description?.trim() || `Transfer from ${from.name}`,
          transferAccountId: from.id,
          transferPairId: outId,
          transferIn: true,
          fxRateUsed: from.currency === to.currency ? null : rate,
          balanceAfterTransaction: toAfter.currentBalance,
        },
        include: { category: true, account: true, transferAccount: true },
      });
      return { outgoing, incoming };
    });
  }

  /** Rejects categories that are neither the user's own nor built-in. */
  private async assertCategoryUsable(userId: string, categoryId?: string | null) {
    if (!categoryId) return;
    const ok = await this.prisma.category.count({
      where: { id: categoryId, OR: [{ userId }, { isDefault: true }] },
    });
    if (!ok) throw new NotFoundException('Category not found');
  }

  async create(userId: string, dto: CreateTransactionDto) {
    await this.assertCategoryUsable(userId, dto.categoryId);
    const needsClarification =
      (dto.parseConfidence !== undefined && dto.parseConfidence < 0.7) ||
      (dto.categoryConfidence !== undefined && dto.categoryConfidence < 0.7);

    const created = await this.prisma.$transaction(async (tx) => {
      const account = await tx.account.findUnique({
        where: { id: dto.accountId },
      });

      if (!account || account.userId !== userId) {
        throw new NotFoundException('Account not found');
      }

      const delta = balanceDelta(dto.type, dto.amount);
      const updatedAccount = await tx.account.update({
        where: { id: dto.accountId },
        data: {
          currentBalance: {
            increment: new Prisma.Decimal(delta.toFixed(4)),
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
    if (await this.recurring.detect(created)) created.isRecurringGuess = true;
    await this.triggers.afterTransaction(created);
    return created;
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
        include: { category: true, account: true, transferAccount: true },
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
      include: { category: true, account: true, transferAccount: true },
    });

    if (!transaction || transaction.userId !== userId) {
      throw new NotFoundException('Transaction not found');
    }

    return transaction;
  }

  async update(id: string, userId: string, dto: UpdateTransactionDto) {
    await this.assertCategoryUsable(userId, dto.categoryId);
    const current = await this.prisma.transaction.findUnique({
      where: { id },
      select: { userId: true, transferPairId: true },
    });
    if (
      current?.userId === userId &&
      current.transferPairId &&
      (dto.amount !== undefined || dto.type !== undefined || dto.currency !== undefined)
    ) {
      throw new BadRequestException(
        'To change a transfer amount, delete the transfer and record it again',
      );
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const existing = await tx.transaction.findUnique({
        where: { id },
        include: { category: true, account: true, transferAccount: true },
      });

      if (!existing || existing.userId !== userId) {
        throw new NotFoundException('Transaction not found');
      }

      const oldAmount = Number(existing.amount);
      const newAmount = dto.amount ?? oldAmount;
      const oldDelta = balanceDelta(existing.type, oldAmount, existing.transferIn);
      const newType = dto.type ?? existing.type;
      const newDelta = balanceDelta(newType, newAmount, existing.transferIn);
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
        include: { category: true, account: true, transferAccount: true },
      });
    });

    if (dto.amount !== undefined || dto.categoryId || dto.type) {
      await this.triggers.afterTransaction(updated);
    }
    if (dto.categoryId) {
      await this.aliases.learn(
        userId,
        updated.merchantName,
        dto.categoryId,
        updated.type,
      );
    }
    return updated;
  }

  async delete(id: string, userId: string) {
    return this.prisma.$transaction(async (tx) => {
      const transaction = await tx.transaction.findUnique({ where: { id } });

      if (!transaction || transaction.userId !== userId) {
        throw new NotFoundException('Transaction not found');
      }

      // A transfer is deleted as a whole: both legs, both balances.
      const pair = transaction.transferPairId
        ? await tx.transaction.findUnique({ where: { id: transaction.transferPairId } })
        : null;
      for (const leg of pair ? [transaction, pair] : [transaction]) {
        const reverse = -balanceDelta(leg.type, Number(leg.amount), leg.transferIn);
        await tx.account.update({
          where: { id: leg.accountId },
          data: {
            currentBalance: { increment: new Prisma.Decimal(reverse.toFixed(4)) },
          },
        });
      }
      if (pair) await tx.transaction.delete({ where: { id: pair.id } });
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

}
