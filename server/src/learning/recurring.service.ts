import { Injectable } from '@nestjs/common';
import type { Transaction } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { MerchantAliasService } from './merchant-alias.service.js';

const DAY = 24 * 60 * 60 * 1000;

/** Cadences we recognise, as [min, max] days between payments. */
const CADENCES: Array<[number, number]> = [
  [6, 8], // weekly
  [13, 16], // fortnightly
  [26, 35], // monthly
  [85, 97], // quarterly
];

/**
 * Spots subscriptions, rent, salaries and other repeating payments: same
 * merchant, similar amount (within 10%), at a regular interval. Needs the
 * new transaction plus at least two earlier ones.
 */
@Injectable()
export class RecurringService {
  constructor(private prisma: PrismaService) {}

  /** Who was paid: merchant, else counterparty, else a typed description. */
  static key(tx: Pick<Transaction, 'merchantName' | 'counterparty' | 'description'>) {
    return (
      MerchantAliasService.normalize(tx.merchantName) ??
      MerchantAliasService.normalize(tx.counterparty) ??
      MerchantAliasService.normalize(tx.description, { isMerchantName: false })
    );
  }

  static isRegular(dates: Date[]): boolean {
    if (dates.length < 3) return false;
    const sorted = [...dates].sort((a, b) => a.getTime() - b.getTime());
    const gaps = sorted
      .slice(1)
      .map((d, i) => (d.getTime() - sorted[i].getTime()) / DAY);
    return CADENCES.some(([min, max]) => gaps.every((g) => g >= min && g <= max));
  }

  /** Checks [tx] against its history and flags the series if it repeats. */
  async detect(tx: Transaction): Promise<boolean> {
    const key = RecurringService.key(tx);
    if (!key) return false;

    const amount = Number(tx.amount);
    const candidates = await this.prisma.transaction.findMany({
      where: {
        userId: tx.userId,
        type: tx.type,
        currency: tx.currency,
        id: { not: tx.id },
        occurredAt: {
          gte: new Date(tx.occurredAt.getTime() - 400 * DAY),
          lt: tx.occurredAt,
        },
        amount: { gte: amount * 0.9, lte: amount * 1.1 },
      },
      orderBy: { occurredAt: 'desc' },
      take: 50,
    });
    const series = candidates
      .filter((c) => RecurringService.key(c) === key)
      .slice(0, 5);

    // Use the most recent run of payments that is itself regular.
    for (let n = series.length; n >= 2; n--) {
      const run = series.slice(0, n);
      if (RecurringService.isRegular([tx.occurredAt, ...run.map((c) => c.occurredAt)])) {
        await this.prisma.transaction.updateMany({
          where: { id: { in: [tx.id, ...run.map((c) => c.id)] } },
          data: { isRecurringGuess: true },
        });
        return true;
      }
    }
    return false;
  }
}
