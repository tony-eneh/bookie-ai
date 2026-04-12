import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateConnectedAccountDto } from './dto/create-connected-account.dto.js';

@Injectable()
export class ConnectedAccountsService {
  constructor(private prisma: PrismaService) {}

  async findAll(userId: string) {
    return this.prisma.connectedAccount.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(userId: string, dto: CreateConnectedAccountDto) {
    const existing = await this.prisma.connectedAccount.findFirst({
      where: {
        userId,
        providerType: dto.providerType,
        providerEmail: dto.providerEmail,
      },
    });

    if (existing) {
      return this.prisma.connectedAccount.update({
        where: { id: existing.id },
        data: {
          accessToken: dto.accessToken,
          refreshToken: dto.refreshToken,
          scopes: dto.scopes,
          status: 'ACTIVE',
        },
      });
    }

    return this.prisma.connectedAccount.create({
      data: {
        userId,
        providerType: dto.providerType,
        providerEmail: dto.providerEmail,
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
        scopes: dto.scopes,
      },
    });
  }

  async revoke(id: string, userId: string) {
    const connectedAccount = await this.prisma.connectedAccount.findUnique({
      where: { id },
    });

    if (!connectedAccount) {
      throw new NotFoundException('Connected account not found');
    }

    if (connectedAccount.userId !== userId) {
      throw new ForbiddenException('Cannot revoke this connected account');
    }

    return this.prisma.connectedAccount.update({
      where: { id },
      data: {
        status: 'REVOKED',
        accessToken: null,
        refreshToken: null,
      },
    });
  }

  async delete(id: string, userId: string) {
    const connectedAccount = await this.prisma.connectedAccount.findUnique({
      where: { id },
    });

    if (!connectedAccount) {
      throw new NotFoundException('Connected account not found');
    }

    if (connectedAccount.userId !== userId) {
      throw new ForbiddenException('Cannot delete this connected account');
    }

    return this.prisma.connectedAccount.delete({ where: { id } });
  }
}