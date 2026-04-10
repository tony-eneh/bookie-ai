import { Injectable, NotFoundException } from '@nestjs/common';
import type { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { AiService } from '../ai/ai.service.js';

@Injectable()
export class AssistantService {
  constructor(
    private prisma: PrismaService,
    private aiService: AiService,
  ) {}

  async chat(userId: string, message: string) {
    const userData = await this.gatherUserContext(userId);
    const response = await this.aiService.answerFinanceQuestion(message, userData);
    return response;
  }

  async voiceQuery(userId: string, text: string) {
    return this.chat(userId, text);
  }

  async clarifyTransaction(userId: string, transactionId: string, userInput: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
      include: { clarifications: { where: { status: 'PENDING' }, take: 1 } },
    });

    if (!transaction || transaction.userId !== userId) {
      throw new NotFoundException('Transaction not found');
    }

    const classification = await this.aiService.classifyCategory(
      userInput,
      transaction.merchantName ?? undefined,
    );

    const category = await this.prisma.category.findFirst({
      where: {
        name: { contains: classification.categoryName, mode: 'insensitive' },
        OR: [{ userId }, { isDefault: true }],
      },
    });

    const updateData: Record<string, unknown> = {
      needsClarification: false,
      clarificationStatus: 'ANSWERED',
    };
    if (category) {
      updateData.categoryId = category.id;
      updateData.categoryConfidence = classification.confidence;
    }

    const updated = await this.prisma.transaction.update({
      where: { id: transactionId },
      data: updateData,
      include: { category: true, account: true },
    });

    if (transaction.clarifications.length > 0) {
      await this.prisma.clarification.update({
        where: { id: transaction.clarifications[0].id },
        data: {
          answerText: userInput,
          answerSource: 'TEXT',
          status: 'ANSWERED',
          resolvedAt: new Date(),
        },
      });
    }

    return {
      transaction: updated,
      classifiedCategory: classification.categoryName,
      confidence: classification.confidence,
    };
  }

  async goalPlanning(
    userId: string,
    input: {
      targetAmount: number;
      targetDate: string;
      currentSavings: number;
      monthlyExpenses: number;
      averageIncome: number;
    },
  ) {
    const plan = await this.aiService.planGoal(input);

    await this.prisma.scenarioSimulation.create({
      data: {
        userId,
        inputPayload: input as unknown as Prisma.InputJsonValue,
        resultPayload: plan as unknown as Prisma.InputJsonValue,
      },
    });

    return plan;
  }

  async scenario(
    userId: string,
    input: { scenarioType: string; parameters: Record<string, unknown> },
  ) {
    const result = await this.aiService.simulateScenario(input);

    await this.prisma.scenarioSimulation.create({
      data: {
        userId,
        inputPayload: input as unknown as Prisma.InputJsonValue,
        resultPayload: result as unknown as Prisma.InputJsonValue,
      },
    });

    return result;
  }

  async fxSimulation(
    userId: string,
    input: { amount: number; sourceCurrency: string; targetCurrency: string },
  ) {
    return this.aiService.simulateFx(input);
  }

  private async gatherUserContext(userId: string) {
    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);

    const [user, accounts, recentTxs] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.account.findMany({ where: { userId, isActive: true } }),
      this.prisma.transaction.findMany({
        where: { userId, occurredAt: { gte: monthStart } },
        orderBy: { occurredAt: 'desc' },
        take: 20,
      }),
    ]);

    const totalBalance = accounts.reduce(
      (sum, a) => sum + Number(a.currentBalance),
      0,
    );
    const monthlyIncome = recentTxs
      .filter((tx) => tx.type === 'INCOME')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);
    const monthlyExpenses = recentTxs
      .filter((tx) => tx.type === 'EXPENSE')
      .reduce((sum, tx) => sum + Number(tx.amount), 0);

    return {
      name: user?.fullName,
      currency: user?.primaryCurrency,
      totalBalance: Number(totalBalance.toFixed(2)),
      monthlyIncome: Number(monthlyIncome.toFixed(2)),
      monthlyExpenses: Number(monthlyExpenses.toFixed(2)),
      accountCount: accounts.length,
      recentTransactionCount: recentTxs.length,
    };
  }
}
