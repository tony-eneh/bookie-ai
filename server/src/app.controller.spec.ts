import { ServiceUnavailableException } from '@nestjs/common';
import { AppController } from './app.controller.js';
import type { AiService } from './ai/ai.service.js';
import type { PrismaService } from './prisma/prisma.service.js';

describe('AppController', () => {
  const ai = { isLive: () => false } as unknown as AiService;

  it('reports ok when the database answers', async () => {
    const prisma = { $queryRaw: jest.fn().mockResolvedValue([1]) };
    const controller = new AppController(
      prisma as unknown as PrismaService,
      ai,
    );
    await expect(controller.health()).resolves.toMatchObject({
      status: 'ok',
      db: 'ok',
      ai: 'mock',
    });
  });

  it('returns 503 when the database is down', async () => {
    const prisma = { $queryRaw: jest.fn().mockRejectedValue(new Error('x')) };
    const controller = new AppController(
      prisma as unknown as PrismaService,
      ai,
    );
    await expect(controller.health()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });
});
