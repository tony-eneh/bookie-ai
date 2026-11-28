import { ForbiddenException, Injectable } from '@nestjs/common';
import { compare } from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service.js';
import { publicConnectedAccount } from '../connected-accounts/connected-accounts.service.js';
import type { Prisma } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }

  /**
   * Everything stored about the user, for "export my data". Secrets
   * (password hash, session/reset tokens, OAuth tokens) are left out.
   */
  async exportData(userId: string) {
    const where = { userId };
    const [
      user,
      accounts,
      transactions,
      categories,
      budgets,
      goals,
      clarifications,
      incomeTargets,
      merchantAliases,
      notifications,
      insights,
      statementImports,
      scenarioSimulations,
      connectedAccounts,
    ] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.account.findMany({
        where,
        include: { reconciliations: true },
      }),
      this.prisma.transaction.findMany({ where, orderBy: { occurredAt: 'asc' } }),
      this.prisma.category.findMany({ where }),
      this.prisma.budget.findMany({ where }),
      this.prisma.goal.findMany({ where, include: { contributions: true } }),
      this.prisma.clarification.findMany({ where }),
      this.prisma.incomeTarget.findMany({ where }),
      this.prisma.merchantAlias.findMany({ where }),
      this.prisma.notification.findMany({ where }),
      this.prisma.insight.findMany({ where }),
      this.prisma.statementImport.findMany({ where }),
      this.prisma.scenarioSimulation.findMany({ where }),
      this.prisma.connectedAccount.findMany({ where }),
    ]);
    const profile = user ? { ...user, passwordHash: undefined } : null;
    return {
      exportedAt: new Date().toISOString(),
      format: 'bookie-ai-export/v1',
      profile,
      accounts,
      transactions,
      categories,
      budgets,
      goals,
      clarifications,
      incomeTargets,
      merchantAliases,
      notifications,
      insights,
      statementImports,
      scenarioSimulations,
      connectedAccounts: connectedAccounts.map(publicConnectedAccount),
    };
  }

  /**
   * Permanently deletes the user and (via cascades) all of their data.
   * Accounts with a password must confirm it.
   */
  async deleteAccount(userId: string, password?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) return { deleted: true };
    if (user.passwordHash) {
      if (!password || !(await compare(password, user.passwordHash))) {
        throw new ForbiddenException('Password is incorrect');
      }
    }
    await this.prisma.user.delete({ where: { id: userId } });
    return { deleted: true };
  }

  /** Case-insensitive, since older accounts may have mixed-case emails. */
  async findByEmail(email: string) {
    return this.prisma.user.findFirst({
      where: { email: { equals: email.trim(), mode: 'insensitive' } },
    });
  }

  async create(data: Prisma.UserCreateInput) {
    return this.prisma.user.create({ data });
  }

  async update(id: string, data: Prisma.UserUpdateInput) {
    return this.prisma.user.update({ where: { id }, data });
  }

  async updatePreferences(
    id: string,
    data: Pick<
      Prisma.UserUpdateInput,
      'notificationMode' | 'financialPersonality' | 'fxPreference' | 'incomeStyle'
    >,
  ) {
    return this.prisma.user.update({ where: { id }, data });
  }
}
