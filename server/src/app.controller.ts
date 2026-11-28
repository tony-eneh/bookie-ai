import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { AiService } from './ai/ai.service.js';
import { PrismaService } from './prisma/prisma.service.js';

@ApiTags('health')
@SkipThrottle()
@Controller()
export class AppController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly ai: AiService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Service info' })
  root() {
    return { name: 'BookieAI API', docs: '/api/docs', health: '/api/health' };
  }

  @Get('health')
  @ApiOperation({ summary: 'Liveness and database check (for monitors)' })
  async health() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      throw new ServiceUnavailableException({ status: 'error', db: 'down' });
    }
    return {
      status: 'ok',
      db: 'ok',
      ai: this.ai.isLive() ? 'live' : 'mock',
      time: new Date().toISOString(),
    };
  }
}
