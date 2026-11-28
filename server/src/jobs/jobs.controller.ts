import {
  Controller,
  Get,
  Headers,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiExcludeController } from '@nestjs/swagger';
import { SkipThrottle } from '@nestjs/throttler';
import { timingSafeEqual } from 'node:crypto';
import { JobsService } from './jobs.service.js';

/**
 * Called by Vercel Cron (see server/vercel.json). Vercel sends
 * `Authorization: Bearer $CRON_SECRET` when CRON_SECRET is set on the
 * project; without it the endpoint stays disabled.
 */
@ApiExcludeController()
@SkipThrottle()
@Controller('jobs')
export class JobsController {
  constructor(
    private jobs: JobsService,
    private config: ConfigService,
  ) {}

  @Get('daily')
  daily(@Headers('authorization') authorization?: string) {
    const secret = this.config.get<string>('CRON_SECRET');
    if (!secret) {
      throw new ServiceUnavailableException('Scheduled jobs are not configured');
    }
    const expected = Buffer.from(`Bearer ${secret}`);
    const given = Buffer.from(authorization ?? '');
    if (given.length !== expected.length || !timingSafeEqual(given, expected)) {
      throw new UnauthorizedException();
    }
    return this.jobs.daily();
  }
}
