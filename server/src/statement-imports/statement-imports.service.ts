import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateStatementImportDto } from './dto/create-statement-import.dto.js';

@Injectable()
export class StatementImportsService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string) {
    return this.prisma.statementImport.findMany({
      where: { userId },
      include: { account: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string, userId: string) {
    const statementImport = await this.prisma.statementImport.findUnique({
      where: { id },
      include: { account: true },
    });

    if (!statementImport) {
      throw new NotFoundException('Statement import not found');
    }

    if (statementImport.userId !== userId) {
      throw new ForbiddenException('Cannot access this statement import');
    }

    return statementImport;
  }

  async create(userId: string, dto: CreateStatementImportDto) {
    return this.prisma.$transaction(async (tx) => {
      const account = await tx.account.findUnique({ where: { id: dto.accountId } });

      if (!account) {
        throw new NotFoundException('Account not found');
      }

      if (account.userId !== userId) {
        throw new ForbiddenException('Cannot import into this account');
      }

      const statementImport = await tx.statementImport.create({
        data: {
          userId,
          accountId: dto.accountId,
          source: dto.source,
          fileType: dto.fileType,
          parsedSuccessfully: false,
          transactionsImported: 0,
        },
      });

      let runningBalance = Number(account.currentBalance);
      const sortedEntries = [...dto.transactions].sort(
        (left, right) =>
          new Date(left.occurredAt).getTime() - new Date(right.occurredAt).getTime(),
      );

      for (const entry of sortedEntries) {
        const delta = this.getBalanceDelta(entry.type, entry.amount);
        runningBalance += delta;

        await tx.transaction.create({
          data: {
            userId,
            accountId: dto.accountId,
            type: entry.type,
            amount: entry.amount,
            currency: entry.currency,
            occurredAt: new Date(entry.occurredAt),
            description: entry.description,
            merchantName: entry.merchantName,
            categoryId: entry.categoryId,
            sourceType: 'AI_IMPORT',
            parseConfidence: 1,
            categoryConfidence: entry.categoryId ? 1 : 0.5,
            needsClarification: false,
            clarificationStatus: 'NONE',
            balanceAfterTransaction: new Prisma.Decimal(runningBalance.toFixed(4)),
            sourceRef: statementImport.id,
          },
        });
      }

      await tx.account.update({
        where: { id: account.id },
        data: {
          currentBalance: new Prisma.Decimal(runningBalance.toFixed(4)),
        },
      });

      return tx.statementImport.update({
        where: { id: statementImport.id },
        data: {
          parsedSuccessfully: true,
          transactionsImported: sortedEntries.length,
        },
        include: { account: true },
      });
    });
  }

  private getBalanceDelta(type: string, amount: number) {
    if (type === 'INCOME') {
      return amount;
    }

    return -amount;
  }
}