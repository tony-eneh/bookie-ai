import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateAccountDto } from './dto/create-account.dto.js';
import { UpdateAccountDto } from './dto/update-account.dto.js';
import { ReconcileAccountDto } from './dto/reconcile-account.dto.js';
import { Decimal } from '../../generated/prisma/internal/prismaNamespace.js';

@Injectable()
export class AccountsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, dto: CreateAccountDto) {
    return this.prisma.account.create({
      data: {
        userId,
        name: dto.name,
        type: dto.type,
        currency: dto.currency ?? 'USD',
        currentBalance: dto.initialBalance ?? 0,
        isPrimary: dto.isPrimary ?? false,
      },
    });
  }

  async findAll(userId: string) {
    const accounts = await this.prisma.account.findMany({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'asc' },
    });

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { primaryCurrency: true },
    });

    const primaryCurrency = user?.primaryCurrency ?? 'USD';

    const result = await Promise.all(
      accounts.map(async (account) => {
        let convertedBalance: number | null = null;

        if (account.currency !== primaryCurrency) {
          const fxRate = await this.prisma.fxRate.findUnique({
            where: {
              baseCurrency_targetCurrency: {
                baseCurrency: account.currency,
                targetCurrency: primaryCurrency,
              },
            },
          });

          if (fxRate) {
            convertedBalance =
              Number(account.currentBalance) * Number(fxRate.rate);
          }
        } else {
          convertedBalance = Number(account.currentBalance);
        }

        return {
          ...account,
          currentBalance: Number(account.currentBalance),
          convertedBalance,
          convertedCurrency: primaryCurrency,
        };
      }),
    );

    return result;
  }

  async findById(id: string, userId: string) {
    const account = await this.prisma.account.findUnique({ where: { id } });

    if (!account || account.userId !== userId) {
      throw new NotFoundException('Account not found');
    }

    return account;
  }

  async update(id: string, userId: string, dto: UpdateAccountDto) {
    const account = await this.findById(id, userId);

    const data: Record<string, unknown> = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.type !== undefined) data.type = dto.type;
    if (dto.currency !== undefined) data.currency = dto.currency;
    if (dto.isPrimary !== undefined) data.isPrimary = dto.isPrimary;
    if (dto.initialBalance !== undefined)
      data.currentBalance = dto.initialBalance;

    return this.prisma.account.update({
      where: { id: account.id },
      data,
    });
  }

  async delete(id: string, userId: string) {
    const account = await this.findById(id, userId);

    return this.prisma.account.update({
      where: { id: account.id },
      data: { isActive: false },
    });
  }

  async getBalance(id: string, userId: string) {
    const account = await this.findById(id, userId);

    const hasReconciliation = account.lastReconciledAt !== null;
    const daysSinceReconciliation = hasReconciliation
      ? Math.floor(
          (Date.now() - account.lastReconciledAt!.getTime()) /
            (1000 * 60 * 60 * 24),
        )
      : null;

    let confidence: 'HIGH' | 'MEDIUM' | 'LOW';
    if (!hasReconciliation) {
      confidence = 'LOW';
    } else if (daysSinceReconciliation! <= 7) {
      confidence = 'HIGH';
    } else if (daysSinceReconciliation! <= 30) {
      confidence = 'MEDIUM';
    } else {
      confidence = 'LOW';
    }

    return {
      currentBalance: Number(account.currentBalance),
      lastReconciledBalance: account.lastReconciledBalance
        ? Number(account.lastReconciledBalance)
        : null,
      lastReconciledAt: account.lastReconciledAt,
      currency: account.currency,
      confidence,
    };
  }

  async reconcile(id: string, userId: string, dto: ReconcileAccountDto) {
    const account = await this.findById(id, userId);

    const currentBalance = Number(account.currentBalance);
    const drift = dto.balance - currentBalance;

    const reconciliation = await this.prisma.accountReconciliation.create({
      data: {
        accountId: account.id,
        balance: dto.balance,
        source: dto.source,
        driftAmount: drift,
      },
    });

    await this.prisma.account.update({
      where: { id: account.id },
      data: {
        currentBalance: dto.balance,
        lastReconciledBalance: dto.balance,
        lastReconciledAt: new Date(),
      },
    });

    // Create adjustment transaction if there's drift
    if (Math.abs(drift) > 0.001) {
      await this.prisma.transaction.create({
        data: {
          userId,
          accountId: account.id,
          type: drift > 0 ? 'INCOME' : 'EXPENSE',
          amount: new Decimal(Math.abs(drift).toFixed(4)),
          currency: account.currency,
          occurredAt: new Date(),
          description: `Reconciliation adjustment (${dto.source})`,
          sourceType: 'MANUAL',
          parseConfidence: 1.0,
          categoryConfidence: 1.0,
          balanceAfterTransaction: dto.balance,
          isBalanceSource: true,
        },
      });
    }

    return {
      reconciliation,
      drift,
      adjustmentCreated: Math.abs(drift) > 0.001,
    };
  }

  async getReconciliations(id: string, userId: string) {
    await this.findById(id, userId);

    return this.prisma.accountReconciliation.findMany({
      where: { accountId: id },
      orderBy: { createdAt: 'desc' },
    });
  }
}
