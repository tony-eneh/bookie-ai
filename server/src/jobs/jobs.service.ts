import { Injectable, Logger } from '@nestjs/common';
import type { GoalStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { FxRatesService } from '../fx-rates/fx-rates.service.js';
import { GoalsService } from '../goals/goals.service.js';
import { NotificationsService } from '../notifications/notifications.service.js';

const DAY = 24 * 60 * 60 * 1000;
/** Keep one run well inside a serverless function's time limit. */
const MAX_USERS_PER_RUN = 500;

/**
 * Work that runs once a day (Vercel Cron -> GET /api/jobs/daily):
 * refresh exchange rates, flag goals that have slipped, and on Mondays send
 * last week's summary to users who asked for them.
 */
@Injectable()
export class JobsService {
  private readonly logger = new Logger(JobsService.name);

  constructor(
    private prisma: PrismaService,
    private fxRates: FxRatesService,
    private goals: GoalsService,
    private notifications: NotificationsService,
  ) {}

  async daily(now = new Date()) {
    const results = {
      fxBases: await this.refreshFx(),
      goalAlerts: await this.goalRisk(now),
      weeklySummaries: now.getUTCDay() === 1 ? await this.weeklySummaries(now) : 0,
    };
    this.logger.log(`Daily job: ${JSON.stringify(results)}`);
    return results;
  }

  /** Re-fetch rates for every currency an account is held in. */
  async refreshFx(): Promise<number> {
    const currencies = await this.prisma.account.findMany({
      where: { isActive: true },
      distinct: ['currency'],
      select: { currency: true },
    });
    for (const { currency } of currencies) {
      await this.fxRates.fetchRates(currency);
    }
    return currencies.length;
  }

  /** Recompute goal status; tell the user once when a goal slips. */
  async goalRisk(now: Date): Promise<number> {
    const goals = await this.prisma.goal.findMany({
      where: {
        status: { not: 'ACHIEVED' },
        user: { notificationMode: { not: 'MINIMAL' } },
      },
      take: MAX_USERS_PER_RUN * 5,
    });
    let sent = 0;
    for (const goal of goals) {
      const status: GoalStatus = this.goals.calculateStatus(goal);
      if (status === goal.status) continue;
      await this.prisma.goal.update({ where: { id: goal.id }, data: { status } });
      if (status !== 'AT_RISK' && status !== 'OFF_TRACK') continue;

      const key = `goal:${goal.id}:${status}:${now.toISOString().slice(0, 10)}`;
      await this.notifications.create(
        goal.userId,
        'goal_risk',
        `${goal.title} needs attention`,
        status === 'OFF_TRACK'
          ? "At the current pace you'll miss the target date. Open the goal to see what it takes."
          : "You're slightly behind. A small top-up this month gets you back on track.",
        { key, goalId: goal.id },
      );
      sent++;
    }
    return sent;
  }

  /** Last 7 days in each user's currency, for PROACTIVE and COACH modes. */
  async weeklySummaries(now: Date): Promise<number> {
    const since = new Date(now.getTime() - 7 * DAY);
    const users = await this.prisma.user.findMany({
      where: { notificationMode: { in: ['PROACTIVE', 'COACH'] } },
      select: { id: true, primaryCurrency: true },
      take: MAX_USERS_PER_RUN,
    });
    let sent = 0;
    for (const user of users) {
      const txs = await this.prisma.transaction.findMany({
        where: {
          userId: user.id,
          occurredAt: { gte: since, lt: now },
          type: { in: ['INCOME', 'EXPENSE'] },
          isBalanceSource: false,
        },
        select: { type: true, amount: true, currency: true },
      });
      if (txs.length === 0) continue;
      const currency = user.primaryCurrency;
      const convert = await this.fxRates.loadConverter(
        txs.map((t) => [t.currency, currency] as [string, string]),
      );
      const total = (type: string) =>
        txs
          .filter((t) => t.type === type)
          .reduce((sum, t) => sum + convert(Number(t.amount), t.currency, currency), 0);
      const money = (v: number) =>
        new Intl.NumberFormat('en', {
          style: 'currency',
          currency,
          maximumFractionDigits: 0,
        }).format(v);

      await this.notifications.create(
        user.id,
        'weekly_summary',
        'Your week',
        `Last 7 days: ${money(total('EXPENSE'))} spent, ${money(total('INCOME'))} earned. Tap for details.`,
        { key: `weekly:${user.id}:${now.toISOString().slice(0, 10)}` },
      );
      sent++;
    }
    return sent;
  }
}
