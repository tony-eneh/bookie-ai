import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { RespondClarificationDto } from './dto/respond-clarification.dto.js';
import type { ClarificationItemStatus } from '../../generated/prisma/client.js';

@Injectable()
export class ClarificationsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, transactionId: string, questionText: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id: transactionId },
    });

    if (!transaction || transaction.userId !== userId) {
      throw new NotFoundException('Transaction not found');
    }

    const clarification = await this.prisma.clarification.create({
      data: {
        userId,
        transactionId,
        questionText,
        status: 'PENDING',
      },
    });

    await this.prisma.transaction.update({
      where: { id: transactionId },
      data: {
        needsClarification: true,
        clarificationStatus: 'PENDING',
      },
    });

    return clarification;
  }

  async findAll(userId: string, status?: ClarificationItemStatus) {
    const where: { userId: string; status?: ClarificationItemStatus } = {
      userId,
    };
    if (status) where.status = status;

    return this.prisma.clarification.findMany({
      where,
      include: { transaction: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string, userId: string) {
    const clarification = await this.prisma.clarification.findUnique({
      where: { id },
      include: { transaction: true },
    });

    if (!clarification || clarification.userId !== userId) {
      throw new NotFoundException('Clarification not found');
    }

    return clarification;
  }

  async respond(id: string, userId: string, dto: RespondClarificationDto) {
    const clarification = await this.findById(id, userId);

    const updated = await this.prisma.clarification.update({
      where: { id },
      data: {
        answerText: dto.answerText,
        answerSource: dto.answerSource,
        status: 'ANSWERED',
        resolvedAt: new Date(),
      },
      include: { transaction: true },
    });

    const transactionUpdate: Record<string, unknown> = {
      needsClarification: false,
      clarificationStatus: 'ANSWERED',
    };

    if (dto.categoryId) {
      transactionUpdate.categoryId = dto.categoryId;
    }
    if (dto.transactionType) {
      transactionUpdate.type = dto.transactionType;
    }

    await this.prisma.transaction.update({
      where: { id: clarification.transactionId },
      data: transactionUpdate,
    });

    return updated;
  }

  async dismiss(id: string, userId: string) {
    const clarification = await this.findById(id, userId);

    const updated = await this.prisma.clarification.update({
      where: { id },
      data: {
        status: 'DISMISSED',
        resolvedAt: new Date(),
      },
      include: { transaction: true },
    });

    await this.prisma.transaction.update({
      where: { id: clarification.transactionId },
      data: {
        clarificationStatus: 'DISMISSED',
      },
    });

    return updated;
  }
}
