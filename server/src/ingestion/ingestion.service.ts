import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { AiService } from '../ai/ai.service.js';
import { ParseSmsDto } from './dto/parse-sms.dto.js';
import { ParseEmailDto } from './dto/parse-email.dto.js';
import { VoiceLogDto } from './dto/voice-log.dto.js';
import { ManualEntryDto } from './dto/manual-entry.dto.js';

@Injectable()
export class IngestionService {
  constructor(
    private prisma: PrismaService,
    private aiService: AiService,
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
    const account = await this.prisma.account.findUnique({
      where: { id: dto.accountId },
    });

    if (!account || account.userId !== userId) {
      throw new NotFoundException('Account not found');
    }

    const currentBalance = Number(account.currentBalance);
    let newBalance: number;
    if (dto.type === 'INCOME') {
      newBalance = currentBalance + dto.amount;
    } else {
      newBalance = currentBalance - dto.amount;
    }

    const transaction = await this.prisma.transaction.create({
      data: {
        userId,
        accountId: dto.accountId,
        type: dto.type,
        amount: dto.amount,
        currency: dto.currency,
        occurredAt: dto.occurredAt ? new Date(dto.occurredAt) : new Date(),
        description: dto.description,
        merchantName: dto.merchantName,
        categoryId: dto.categoryId,
        sourceType: 'MANUAL',
        parseConfidence: 1.0,
        categoryConfidence: dto.categoryId ? 1.0 : 0.5,
        needsClarification: false,
        clarificationStatus: 'NONE',
        balanceAfterTransaction: newBalance,
      },
      include: { category: true, account: true },
    });

    await this.prisma.account.update({
      where: { id: dto.accountId },
      data: { currentBalance: newBalance },
    });

    return { transaction, clarification: null };
  }

  private async parseRawText(
    userId: string,
    rawText: string,
    accountId: string | undefined,
    sourceType: 'SMS' | 'EMAIL' | 'VOICE',
  ) {
    const parsed = await this.aiService.parseTransaction(rawText);

    // Resolve account: use provided accountId or find the user's primary account
    let resolvedAccountId = accountId;
    if (!resolvedAccountId) {
      const primaryAccount = await this.prisma.account.findFirst({
        where: { userId, isPrimary: true, isActive: true },
      });
      if (!primaryAccount) {
        const anyAccount = await this.prisma.account.findFirst({
          where: { userId, isActive: true },
        });
        if (!anyAccount) {
          throw new NotFoundException(
            'No active account found. Please create an account first.',
          );
        }
        resolvedAccountId = anyAccount.id;
      } else {
        resolvedAccountId = primaryAccount.id;
      }
    } else {
      const account = await this.prisma.account.findUnique({
        where: { id: resolvedAccountId },
      });
      if (!account || account.userId !== userId) {
        throw new NotFoundException('Account not found');
      }
    }

    // Classify category if AI didn't determine one
    let categoryId: string | null = null;
    let categoryConfidence = 0.5;

    if (parsed.categoryGuess) {
      const category = await this.prisma.category.findFirst({
        where: {
          name: { contains: parsed.categoryGuess, mode: 'insensitive' },
          OR: [{ userId }, { isDefault: true }],
        },
      });
      if (category) {
        categoryId = category.id;
        categoryConfidence = parsed.confidence;
      }
    }

    if (!categoryId) {
      const classification = await this.aiService.classifyCategory(
        parsed.description,
        parsed.merchantName ?? undefined,
      );
      const category = await this.prisma.category.findFirst({
        where: {
          name: { contains: classification.categoryName, mode: 'insensitive' },
          OR: [{ userId }, { isDefault: true }],
        },
      });
      if (category) {
        categoryId = category.id;
        categoryConfidence = classification.confidence;
      }
    }

    const account = await this.prisma.account.findUnique({
      where: { id: resolvedAccountId },
    });
    const currentBalance = Number(account!.currentBalance);
    let newBalance: number;
    if (parsed.type === 'INCOME') {
      newBalance = currentBalance + parsed.amount;
    } else {
      newBalance = currentBalance - parsed.amount;
    }

    const needsClarification =
      parsed.confidence < 0.7 || parsed.ambiguityFlags.length > 0;

    const transaction = await this.prisma.transaction.create({
      data: {
        userId,
        accountId: resolvedAccountId,
        type: parsed.type,
        amount: parsed.amount,
        currency: parsed.currency,
        occurredAt: new Date(parsed.occurredAt),
        description: parsed.description,
        merchantName: parsed.merchantName,
        counterparty: parsed.counterparty,
        categoryId,
        sourceType,
        rawContent: rawText,
        parseConfidence: parsed.confidence,
        categoryConfidence: categoryConfidence,
        needsClarification,
        clarificationStatus: needsClarification ? 'PENDING' : 'NONE',
        balanceAfterTransaction: newBalance,
      },
      include: { category: true, account: true },
    });

    await this.prisma.account.update({
      where: { id: resolvedAccountId },
      data: { currentBalance: newBalance },
    });

    let clarification = null;
    if (needsClarification) {
      const question =
        await this.aiService.generateClarificationQuestion({
          description: parsed.description,
          merchantName: parsed.merchantName ?? undefined,
          amount: parsed.amount,
          type: parsed.type,
        });

      clarification = await this.prisma.clarification.create({
        data: {
          userId,
          transactionId: transaction.id,
          questionText: question.questionText,
          status: 'PENDING',
        },
      });
    }

    return { transaction, clarification };
  }
}
