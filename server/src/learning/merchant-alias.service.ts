import { Injectable } from '@nestjs/common';
import type { TransactionType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';

/**
 * Remembers which category a user puts each merchant in, so the next
 * transaction from that merchant is categorized without asking (or calling
 * the AI). Learned from clarification answers and manual recategorization.
 */
@Injectable()
export class MerchantAliasService {
  constructor(private prisma: PrismaService) {}

  /** "SHOPRITE  LEKKI #123" -> "shoprite lekki" */
  static normalize(
    merchant: string | null | undefined,
    { isMerchantName = true } = {},
  ): string | null {
    if (!merchant) return null;
    let key = merchant
      .toLowerCase()
      .replace(/[^a-z\s&]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
    if (isMerchantName) {
      // Parsed names often run on into the date or a reference: "SPAR VI on".
      key = key.replace(/\s+(on|at|via|ref|date|txn|trx|for)(\s.*)?$/, '').trim();
    }
    return key.length >= 3 ? key : null;
  }

  /**
   * Finds a learned category: by exact merchant first, then by a learned
   * merchant name appearing in the raw message text.
   */
  async lookup(
    userId: string,
    merchantName: string | null | undefined,
    rawText?: string,
    type?: TransactionType,
  ) {
    const key = MerchantAliasService.normalize(merchantName);
    const aliases = await this.prisma.merchantAlias.findMany({
      where: {
        userId,
        ...(type ? { OR: [{ transactionType: type }, { transactionType: null }] } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
    if (key) {
      const exact = aliases.find((a) => a.matchPattern === key);
      if (exact) return exact;
    }
    const text = MerchantAliasService.normalize(rawText, {
      isMerchantName: false,
    });
    if (text) {
      return (
        aliases
          .filter((a) => a.matchPattern.length >= 4)
          .sort((a, b) => b.matchPattern.length - a.matchPattern.length)
          .find((a) => ` ${text} `.includes(` ${a.matchPattern} `)) ?? null
      );
    }
    return null;
  }

  /** Records (or updates) the user's category for a merchant. */
  async learn(
    userId: string,
    merchantName: string | null | undefined,
    categoryId: string,
    type?: TransactionType,
  ) {
    const key = MerchantAliasService.normalize(merchantName);
    if (!key) return null;
    const existing = await this.prisma.merchantAlias.findFirst({
      where: { userId, matchPattern: key },
    });
    if (existing) {
      return this.prisma.merchantAlias.update({
        where: { id: existing.id },
        data: { categoryId, transactionType: type ?? existing.transactionType },
      });
    }
    return this.prisma.merchantAlias.create({
      data: {
        userId,
        matchPattern: key,
        merchantName: merchantName ?? null,
        categoryId,
        transactionType: type ?? null,
      },
    });
  }
}
