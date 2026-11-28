import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, TransactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateStatementImportDto } from './dto/create-statement-import.dto.js';
import { ImportCsvDto } from './dto/import-csv.dto.js';
import { parseStatementCsv } from './csv.js';

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

  /**
   * Records statement rows in an account, skipping ones already there (same
   * type, amount, day and description). With [adjustBalance] (the JSON API's
   * long-standing behaviour) the rows also move the account balance; a
   * bank statement's history is usually already in the balance, so the CSV
   * import leaves it alone.
   */
  async create(
    userId: string,
    dto: CreateStatementImportDto,
    { adjustBalance = true }: { adjustBalance?: boolean } = {},
  ) {
    return this.prisma.$transaction(async (tx) => {
      const account = await tx.account.findUnique({ where: { id: dto.accountId } });

      if (!account) {
        throw new NotFoundException('Account not found');
      }

      if (account.userId !== userId) {
        throw new ForbiddenException('Cannot import into this account');
      }

      const categoryIds = [
        ...new Set(
          dto.transactions
            .map((t) => t.categoryId)
            .filter((id): id is string => Boolean(id)),
        ),
      ];
      if (categoryIds.length > 0) {
        const allowed = await tx.category.count({
          where: {
            id: { in: categoryIds },
            OR: [{ userId }, { isDefault: true }],
          },
        });
        if (allowed !== categoryIds.length) {
          throw new BadRequestException('Unknown category in imported rows');
        }
      }

      const sorted = [...dto.transactions].sort(
        (l, r) => new Date(l.occurredAt).getTime() - new Date(r.occurredAt).getTime(),
      );

      // Skip rows already recorded (re-imported statement, or already
      // picked up from SMS).
      const fresh: typeof sorted = [];
      if (sorted.length > 0) {
        const day = (d: Date | string) => new Date(d).toISOString().slice(0, 10);
        const from = new Date(sorted[0].occurredAt);
        from.setUTCDate(from.getUTCDate() - 1);
        const to = new Date(sorted[sorted.length - 1].occurredAt);
        to.setUTCDate(to.getUTCDate() + 1);
        const existing = await tx.transaction.findMany({
          where: { accountId: account.id, occurredAt: { gte: from, lte: to } },
          select: { type: true, amount: true, occurredAt: true, description: true },
        });
        // Count-aware: two identical transfers on one day are two rows, so
        // each existing match cancels exactly one incoming row.
        const already = new Map<string, number>();
        for (const e of existing) {
          const key = `${e.type}|${Number(e.amount).toFixed(2)}|${day(e.occurredAt)}|${(e.description ?? '').trim().toLowerCase()}`;
          already.set(key, (already.get(key) ?? 0) + 1);
        }
        for (const entry of sorted) {
          const key = `${entry.type}|${entry.amount.toFixed(2)}|${day(entry.occurredAt)}|${entry.description.trim().toLowerCase()}`;
          const left = already.get(key) ?? 0;
          if (left > 0) {
            already.set(key, left - 1);
            continue;
          }
          fresh.push(entry);
        }
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
      const rows = fresh.map((entry) => {
        if (adjustBalance) {
          runningBalance += this.getBalanceDelta(entry.type, entry.amount);
        }
        return {
          userId,
          accountId: dto.accountId,
          type: entry.type,
          amount: entry.amount,
          currency: entry.currency,
          occurredAt: new Date(entry.occurredAt),
          description: entry.description,
          merchantName: entry.merchantName,
          categoryId: entry.categoryId,
          sourceType: 'AI_IMPORT' as const,
          parseConfidence: 1,
          categoryConfidence: entry.categoryId ? 1 : 0.5,
          needsClarification: false,
          clarificationStatus: 'NONE' as const,
          balanceAfterTransaction: adjustBalance
            ? new Prisma.Decimal(runningBalance.toFixed(4))
            : null,
          sourceRef: statementImport.id,
        };
      });
      // One batch insert instead of a round trip per row.
      if (rows.length > 0) await tx.transaction.createMany({ data: rows });

      if (adjustBalance && rows.length > 0) {
        await tx.account.update({
          where: { id: account.id },
          data: { currentBalance: new Prisma.Decimal(runningBalance.toFixed(4)) },
        });
      }

      const saved = await tx.statementImport.update({
        where: { id: statementImport.id },
        data: {
          parsedSuccessfully: true,
          transactionsImported: rows.length,
        },
        include: { account: true },
      });
      return { ...saved, duplicatesSkipped: sorted.length - fresh.length };
    });
  }

  /** Parses a bank's CSV export and imports it (balance left unchanged). */
  async importCsv(userId: string, dto: ImportCsvDto) {
    const account = await this.prisma.account.findUnique({
      where: { id: dto.accountId },
    });
    if (!account || account.userId !== userId) {
      throw new NotFoundException('Account not found');
    }
    let parsed: ReturnType<typeof parseStatementCsv>;
    try {
      parsed = parseStatementCsv(dto.csv);
    } catch (error) {
      throw new BadRequestException(
        error instanceof Error ? error.message : 'Could not read the CSV file',
      );
    }
    if (parsed.rows.length === 0) {
      throw new BadRequestException('No transactions found in the file');
    }
    const result = await this.create(
      userId,
      {
        accountId: dto.accountId,
        source: dto.fileName ?? 'csv_upload',
        fileType: 'csv',
        transactions: parsed.rows.map((row) => ({
          ...row,
          type: row.type as TransactionType,
          currency: account.currency,
        })),
      },
      { adjustBalance: dto.adjustBalance ?? false },
    );
    return { ...result, linesSkipped: parsed.skippedLines };
  }

  private getBalanceDelta(type: TransactionType, amount: number) {
    switch (type) {
      case TransactionType.INCOME:
        return amount;
      case TransactionType.EXPENSE:
        return -amount;
      default:
        throw new BadRequestException(
          `Statement imports do not support ${type} transactions yet`,
        );
    }
  }
}