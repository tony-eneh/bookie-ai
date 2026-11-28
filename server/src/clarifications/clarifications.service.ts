import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { balanceDelta } from '../common/balance.js';
import { MerchantAliasService } from '../learning/merchant-alias.service.js';
import { RespondClarificationDto } from './dto/respond-clarification.dto.js';
import type { ClarificationItemStatus } from '@prisma/client';

@Injectable()
export class ClarificationsService {
  constructor(
    private prisma: PrismaService,
    private aliases: MerchantAliasService,
  ) {}

  async create(userId: string, transactionId: string, questionText: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction || transaction.userId !== userId) {
      throw new NotFoundException('Transaction not found');
    }

    const clarification = await this.prisma.clarification.create({
      data: {
        userId,
        transactionId,
        questionText,
        status: 'PENDING',
      },
    });

    await this.prisma.transaction.update({
      where: { id: transactionId },
      data: {
        needsClarification: true,
        clarificationStatus: 'PENDING',
      },
    });

    return clarification;
  }

  async findAll(userId: string, status?: ClarificationItemStatus) {
    const where: { userId: string; status?: ClarificationItemStatus } = {
      userId,
    };
    if (status) where.status = status;

    return this.prisma.clarification.findMany({
      where,
      include: { transaction: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string, userId: string) {
    const clarification = await this.prisma.clarification.findUnique({
      where: { id },
      include: { transaction: true },
    });

    if (!clarification || clarification.userId !== userId) {
      throw new NotFoundException('Clarification not found');
    }

    return clarification;
  }

  async respond(id: string, userId: string, dto: RespondClarificationDto) {
    const answered = await this.prisma.$transaction(async (tx) => {
      const clarification = await tx.clarification.findUnique({
        where: { id },
        include: { transaction: true },
      });

      if (!clarification || clarification.userId !== userId) {
        throw new NotFoundException('Clarification not found');
      }

      if (dto.categoryId) {
        const category = await tx.category.findFirst({
          where: {
            id: dto.categoryId,
            OR: [{ userId }, { isDefault: true }],
          },
        });
        if (!category) throw new NotFoundException('Category not found');
      }

      const nextTransactionType =
        dto.transactionType ?? clarification.transaction.type;
      const currentAmount = Number(clarification.transaction.amount);
      const currentDelta = balanceDelta(
        clarification.transaction.type,
        currentAmount,
        clarification.transaction.transferIn,
      );
      const nextDelta = balanceDelta(
        nextTransactionType,
        currentAmount,
        clarification.transaction.transferIn,
      );
      const balanceAdjustment = nextDelta - currentDelta;

      let balanceAfterTransaction = clarification.transaction.balanceAfterTransaction;
      if (Math.abs(balanceAdjustment) > 0.001) {
        const updatedAccount = await tx.account.update({
          where: { id: clarification.transaction.accountId },
          data: {
            currentBalance: {
              increment: new Prisma.Decimal(balanceAdjustment.toFixed(4)),
            },
          },
        });
        balanceAfterTransaction = updatedAccount.currentBalance;
      }

      await tx.clarification.update({
        where: { id },
        data: {
          answerText: dto.answerText,
          answerSource: dto.answerSource,
          status: 'ANSWERED',
          resolvedAt: new Date(),
        },
      });

      const transactionUpdate: Prisma.TransactionUncheckedUpdateInput = {
        needsClarification: false,
        clarificationStatus: 'ANSWERED',
      };

      if (dto.categoryId) {
        transactionUpdate.categoryId = dto.categoryId;
      }
      if (dto.transactionType) {
        transactionUpdate.type = dto.transactionType;
        transactionUpdate.balanceAfterTransaction = balanceAfterTransaction;
      }

      await tx.transaction.update({
        where: { id: clarification.transactionId },
        data: transactionUpdate,
      });

      return tx.clarification.findUnique({
        where: { id },
        include: { transaction: true },
      });
    });

    // Remember the merchant's category so Bookie doesn't ask next time.
    if (dto.categoryId && answered?.transaction) {
      await this.aliases.learn(
        userId,
        answered.transaction.merchantName,
        dto.categoryId,
        answered.transaction.type,
      );
    }
    return answered;
  }

  async dismiss(id: string, userId: string) {
    const clarification = await this.findById(id, userId);

    const updated = await this.prisma.clarification.update({
      where: { id },
      data: {
        status: 'DISMISSED',
        resolvedAt: new Date(),
      },
      include: { transaction: true },
    });

    await this.prisma.transaction.update({
      where: { id: clarification.transactionId },
      data: {
        clarificationStatus: 'DISMISSED',
      },
    });

    return updated;
  }

}
