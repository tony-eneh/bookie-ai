import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { ConnectedAccount } from '@prisma/client';
import { TokenCipher } from '../common/crypto/token-cipher.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { CreateConnectedAccountDto } from './dto/create-connected-account.dto.js';

/** What clients may see: never the OAuth tokens themselves. */
export function publicConnectedAccount(account: ConnectedAccount) {
  const { accessToken, refreshToken, ...rest } = account;
  return {
    ...rest,
    hasAccessToken: Boolean(accessToken),
    hasRefreshToken: Boolean(refreshToken),
  };
}

@Injectable()
export class ConnectedAccountsService {
  private readonly cipher: TokenCipher;

  constructor(
    private prisma: PrismaService,
    config: ConfigService,
  ) {
    this.cipher = new TokenCipher({
      encryptionKey: config.get<string>('TOKEN_ENCRYPTION_KEY'),
      jwtSecret: config.get<string>('JWT_SECRET'),
    });
  }

  async findAll(userId: string) {
    const accounts = await this.prisma.connectedAccount.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    return accounts.map(publicConnectedAccount);
  }

  async create(userId: string, dto: CreateConnectedAccountDto) {
    const tokens = {
      accessToken: this.cipher.encrypt(dto.accessToken),
      refreshToken: this.cipher.encrypt(dto.refreshToken),
    };
    const existing = await this.prisma.connectedAccount.findFirst({
      where: {
        userId,
        providerType: dto.providerType,
        providerEmail: dto.providerEmail,
      },
    });

    const saved = existing
      ? await this.prisma.connectedAccount.update({
          where: { id: existing.id },
          data: { ...tokens, scopes: dto.scopes, status: 'ACTIVE' },
        })
      : await this.prisma.connectedAccount.create({
          data: {
            userId,
            providerType: dto.providerType,
            providerEmail: dto.providerEmail,
            ...tokens,
            scopes: dto.scopes,
          },
        });
    return publicConnectedAccount(saved);
  }

  /** Decrypted tokens, for server-side use only (e.g. a mail sync job). */
  async getTokens(id: string, userId: string) {
    const account = await this.findOwned(id, userId, 'read');
    return {
      accessToken: this.cipher.decrypt(account.accessToken),
      refreshToken: this.cipher.decrypt(account.refreshToken),
    };
  }

  async revoke(id: string, userId: string) {
    await this.findOwned(id, userId, 'revoke');
    const updated = await this.prisma.connectedAccount.update({
      where: { id },
      data: {
        status: 'REVOKED',
        accessToken: null,
        refreshToken: null,
      },
    });
    return publicConnectedAccount(updated);
  }

  async delete(id: string, userId: string) {
    await this.findOwned(id, userId, 'delete');
    const deleted = await this.prisma.connectedAccount.delete({ where: { id } });
    return publicConnectedAccount(deleted);
  }

  private async findOwned(id: string, userId: string, action: string) {
    const account = await this.prisma.connectedAccount.findUnique({
      where: { id },
    });
    if (!account) {
      throw new NotFoundException('Connected account not found');
    }
    if (account.userId !== userId) {
      throw new ForbiddenException(`Cannot ${action} this connected account`);
    }
    return account;
  }
}
