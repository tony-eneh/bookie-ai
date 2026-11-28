import { Injectable, Logger } from '@nestjs/common';
import type { NotificationMode, Transaction } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { BudgetsService } from '../budgets/budgets.service.js';
import { NotificationsService } from './notifications.service.js';

const BUDGET_THRESHOLDS = [80, 100] as const;

/**
 * Creates in-app notifications in response to what happens to a user's
 * money. Respects their notification mode; never throws (a failed
 * notification must not fail the transaction that triggered it).
 */
@Injectable()
export class NotificationTriggersService {
  private readonly logger = new Logger(NotificationTriggersService.name);

  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
    private budgets: BudgetsService,
  ) {}

  /** Bookie has a question about a transaction. Sent in every mode. */
  async clarificationNeeded(tx: Transaction, question: string) {
    await this.safely(() =>
      this.notifications.create(tx.userId, 'clarification_needed', 'Quick question', question, {
        transactionId: tx.id,
      }),
    );
  }

  /**
   * After spending is recorded: warn the first time a budget this
   * transaction counts towards passes 80% and 100% in the current period.
   */
  async afterTransaction(tx: Transaction) {
    if (tx.type !== 'EXPENSE') return;
    await this.safely(async () => {
      if ((await this.mode(tx.userId)) === 'MINIMAL') return;

      const budgets = await this.prisma.budget.findMany({
        where: {
          userId: tx.userId,
          isActive: true,
          // Budgets for this category, plus "everything" budgets.
          OR: [
            { categoryId: null },
            ...(tx.categoryId ? [{ categoryId: tx.categoryId }] : []),
          ],
        },
      });
      for (const budget of budgets) {
        const progress = await this.budgets.calculateProgress(budget);
        const crossed = BUDGET_THRESHOLDS.filter(
          (t) => progress.percentageUsed >= t,
        ).pop();
        if (crossed === undefined) continue;

        // One notification per budget, threshold and period.
        const key = `budget:${budget.id}:${crossed}:${progress.periodStart.toISOString()}`;
        const already = await this.prisma.notification.findFirst({
          where: {
            userId: tx.userId,
            type: 'budget_warning',
            actionPayload: { path: ['key'], equals: key },
          },
        });
        if (already) continue;

        const over = crossed >= 100;
        await this.notifications.create(
          tx.userId,
          'budget_warning',
          over ? `${budget.name} is used up` : `${budget.name} is at ${crossed}%`,
          over
            ? `You've spent ${progress.percentageUsed.toFixed(0)}% of this budget for the period.`
            : `You've used ${progress.percentageUsed.toFixed(0)}% so far. Bookie will keep an eye on it.`,
          { key, budgetId: budget.id },
        );
      }
    });
  }

  private async mode(userId: string): Promise<NotificationMode> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { notificationMode: true },
    });
    return user?.notificationMode ?? 'STANDARD';
  }

  private async safely(fn: () => Promise<unknown>) {
    try {
      await fn();
    } catch (error) {
      this.logger.warn(
        `Notification trigger failed: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
