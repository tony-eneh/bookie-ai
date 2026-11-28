import {
  Injectable,
  Logger,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { createHash } from 'node:crypto';
import { Prisma, type Account, type TransactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { AiService } from '../ai/ai.service.js';
import { FxRatesService } from '../fx-rates/fx-rates.service.js';
import { MerchantAliasService } from '../learning/merchant-alias.service.js';
import { ParseSmsDto } from './dto/parse-sms.dto.js';
import { ParseEmailDto } from './dto/parse-email.dto.js';
import { VoiceLogDto } from './dto/voice-log.dto.js';
import { ManualEntryDto } from './dto/manual-entry.dto.js';

type SourceType = 'SMS' | 'EMAIL' | 'VOICE';

/** Alerts for the same payment (e.g. SMS and email) within this window. */
const CROSS_SOURCE_DUPLICATE_WINDOW_MS = 10 * 60 * 1000;

@Injectable()
export class IngestionService {
  private readonly logger = new Logger(IngestionService.name);

  constructor(
    private prisma: PrismaService,
    private aiService: AiService,
    private fxRates: FxRatesService,
    private aliases: MerchantAliasService,
  ) {}

  async parseSms(userId: string, dto: ParseSmsDto) {
    return this.parseRawText(userId, dto.rawText, dto.accountId, 'SMS');
  }

  async parseEmail(userId: string, dto: ParseEmailDto) {
    const text = dto.subject
      ? `Subject: ${dto.subject}\nFrom: ${dto.from ?? 'unknown'}\n${dto.rawText}`
      : dto.rawText;
    return this.parseRawText(userId, text, dto.accountId, 'EMAIL');
  }

  async voiceLog(userId: string, dto: VoiceLogDto) {
    return this.parseRawText(userId, dto.text, dto.accountId, 'VOICE');
  }

  async manualEntry(userId: string, dto: ManualEntryDto) {
    const account = await this.resolveAccount(userId, dto.accountId);
    const amounts = await this.amounts(
      userId,
      dto.amount,
      dto.currency,
      account,
    );
    const delta = this.balanceDelta(dto.type, amounts.inAccountCurrency);

    const transaction = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.account.update({
        where: { id: account.id },
        data: { currentBalance: { increment: new Prisma.Decimal(delta.toFixed(4)) } },
      });
      return tx.transaction.create({
        data: {
          userId,
          accountId: account.id,
          type: dto.type,
          amount: dto.amount,
          currency: dto.currency,
          ...amounts.conversionFields,
          occurredAt: dto.occurredAt ? new Date(dto.occurredAt) : new Date(),
          description: dto.description,
          merchantName: dto.merchantName,
          categoryId: dto.categoryId,
          sourceType: 'MANUAL',
          parseConfidence: 1.0,
          categoryConfidence: dto.categoryId ? 1.0 : 0.5,
          needsClarification: false,
          clarificationStatus: 'NONE',
          balanceAfterTransaction: updated.currentBalance,
        },
        include: { category: true, account: true },
      });
    });

    return { transaction, clarification: null, duplicate: false };
  }

  private async parseRawText(
    userId: string,
    rawText: string,
    accountId: string | undefined,
    sourceType: SourceType,
  ) {
    const text = rawText.trim();
    const account = await this.resolveAccount(userId, accountId);

    // The same message again (e.g. an SMS inbox re-scan): return the original.
    const sourceRef = IngestionService.fingerprint(text);
    if (sourceType !== 'VOICE') {
      const seen = await this.prisma.transaction.findFirst({
        where: { userId, sourceRef },
        include: { category: true, account: true },
      });
      if (seen) return { transaction: seen, clarification: null, duplicate: true };
    }

    const parsed = await this.aiService.parseTransaction(text, {
      defaultCurrency: account.currency,
    });
    if (!(parsed.amount > 0)) {
      throw new UnprocessableEntityException(
        "I couldn't find an amount in that message.",
      );
    }
    const occurredAt = Number.isNaN(Date.parse(parsed.occurredAt))
      ? new Date()
      : new Date(parsed.occurredAt);

    // The same payment reported by another channel (SMS and email alert).
    const crossSource = await this.prisma.transaction.findFirst({
      where: {
        userId,
        accountId: account.id,
        type: parsed.type,
        amount: parsed.amount,
        sourceType: { not: sourceType },
        occurredAt: {
          gte: new Date(occurredAt.getTime() - CROSS_SOURCE_DUPLICATE_WINDOW_MS),
          lte: new Date(occurredAt.getTime() + CROSS_SOURCE_DUPLICATE_WINDOW_MS),
        },
      },
      include: { category: true, account: true },
    });
    if (crossSource) {
      return { transaction: crossSource, clarification: null, duplicate: true };
    }

    // Category: what the user taught us > the AI's guess > a classifier call.
    const { categoryId, categoryConfidence, learned } = await this.categorize(
      userId,
      text,
      parsed.type,
      parsed.merchantName,
      parsed.categoryGuess,
      parsed.description,
      parsed.confidence,
    );

    const flags = learned
      ? parsed.ambiguityFlags.filter((f) => f !== 'MERCHANT_UNKNOWN')
      : parsed.ambiguityFlags;
    const needsClarification =
      !categoryId ||
      categoryConfidence < 0.6 ||
      parsed.confidence < 0.7 ||
      flags.length > 0;

    const amounts = await this.amounts(
      userId,
      parsed.amount,
      parsed.currency,
      account,
    );
    const delta = this.balanceDelta(parsed.type, amounts.inAccountCurrency);

    // AI call happens before the DB transaction to keep it short.
    const question = needsClarification
      ? await this.aiService.generateClarificationQuestion({
          description: parsed.description,
          merchantName: parsed.merchantName ?? undefined,
          amount: parsed.amount,
          type: parsed.type,
        })
      : null;

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.account.update({
        where: { id: account.id },
        data: { currentBalance: { increment: new Prisma.Decimal(delta.toFixed(4)) } },
      });
      const transaction = await tx.transaction.create({
        data: {
          userId,
          accountId: account.id,
          type: parsed.type,
          amount: parsed.amount,
          currency: parsed.currency,
          ...amounts.conversionFields,
          occurredAt,
          description: parsed.description,
          merchantName: parsed.merchantName,
          counterparty: parsed.counterparty,
          categoryId,
          sourceType,
          sourceRef: sourceType === 'VOICE' ? null : sourceRef,
          rawContent: text,
          parseConfidence: parsed.confidence,
          categoryConfidence,
          needsClarification,
          clarificationStatus: needsClarification ? 'PENDING' : 'NONE',
          balanceAfterTransaction: updated.currentBalance,
        },
        include: { category: true, account: true },
      });
      const clarification = question
        ? await tx.clarification.create({
            data: {
              userId,
              transactionId: transaction.id,
              questionText: question.questionText,
              status: 'PENDING',
            },
          })
        : null;
      return { transaction, clarification, duplicate: false };
    });
  }

  /** Stable id for a message, ignoring case and whitespace differences. */
  static fingerprint(text: string): string {
    const normalized = text.toLowerCase().replace(/\s+/g, ' ').trim();
    return `sha256:${createHash('sha256').update(normalized).digest('hex')}`;
  }

  private async resolveAccount(userId: string, accountId?: string): Promise<Account> {
    if (accountId) {
      const account = await this.prisma.account.findUnique({ where: { id: accountId } });
      if (!account || account.userId !== userId) {
        throw new NotFoundException('Account not found');
      }
      return account;
    }
    const account =
      (await this.prisma.account.findFirst({
        where: { userId, isPrimary: true, isActive: true },
      })) ??
      (await this.prisma.account.findFirst({ where: { userId, isActive: true } }));
    if (!account) {
      throw new NotFoundException(
        'No active account found. Please create an account first.',
      );
    }
    return account;
  }

  private async categorize(
    userId: string,
    text: string,
    type: TransactionType,
    merchantName: string | null,
    categoryGuess: string | null,
    description: string,
    parseConfidence: number,
  ): Promise<{ categoryId: string | null; categoryConfidence: number; learned: boolean }> {
    const alias = await this.aliases.lookup(userId, merchantName, text, type);
    if (alias) {
      return { categoryId: alias.categoryId, categoryConfidence: 0.95, learned: true };
    }

    const findByName = (name: string) =>
      this.prisma.category.findFirst({
        where: {
          type,
          name: { contains: name, mode: 'insensitive' },
          OR: [{ userId }, { isDefault: true }],
        },
        orderBy: { userId: { sort: 'asc', nulls: 'last' } }, // user's own wins
      });

    if (categoryGuess) {
      const category = await findByName(categoryGuess);
      if (category) {
        return { categoryId: category.id, categoryConfidence: parseConfidence, learned: false };
      }
    }

    const classification = await this.aiService.classifyCategory(
      description,
      merchantName ?? undefined,
    );
    const category = await findByName(classification.categoryName);
    return {
      categoryId: category?.id ?? null,
      categoryConfidence: category ? classification.confidence : 0.3,
      learned: false,
    };
  }

  /**
   * The amount in the account's currency (for the balance) and, when the
   * transaction isn't in the user's primary currency, the converted amount
   * and rate stored on the transaction. Missing FX rates degrade gracefully.
   */
  private async amounts(
    userId: string,
    amount: number,
    currency: string,
    account: Account,
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { primaryCurrency: true },
    });
    const primary = user?.primaryCurrency ?? account.currency;
    const rate = async (from: string, to: string) => {
      if (from === to) return 1;
      try {
        return await this.fxRates.getRate(from, to);
      } catch {
        this.logger.warn(`No FX rate ${from}->${to}; using the raw amount`);
        return null;
      }
    };

    const toAccount = await rate(currency, account.currency);
    const toPrimary = await rate(currency, primary);
    return {
      inAccountCurrency: amount * (toAccount ?? 1),
      conversionFields:
        currency !== primary && toPrimary !== null
          ? {
              originalCurrency: currency,
              convertedAmount: Number((amount * toPrimary).toFixed(4)),
              fxRateUsed: toPrimary,
            }
          : { originalCurrency: currency },
    };
  }

  private balanceDelta(type: TransactionType | string, amount: number) {
    return type === 'INCOME' ? amount : -amount;
  }
}
