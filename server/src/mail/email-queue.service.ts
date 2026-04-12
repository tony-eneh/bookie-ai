import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue, Worker, type ConnectionOptions } from 'bullmq';
import { MailService } from './mail.service.js';

interface PasswordResetEmailPayload {
  to: string;
  fullName: string;
  resetUrl: string;
  expiresInMinutes: number;
}

@Injectable()
export class EmailQueueService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(EmailQueueService.name);
  private queue: Queue<PasswordResetEmailPayload> | null = null;
  private worker: Worker<PasswordResetEmailPayload> | null = null;

  constructor(
    private configService: ConfigService,
    private mailService: MailService,
  ) {}

  async onModuleInit() {
    const redisUrl = this.configService.get<string>('REDIS_URL');
    if (!redisUrl) {
      this.logger.warn('REDIS_URL is not configured. Email jobs will run inline.');
      return;
    }

    const connection = this.parseRedisConnection(redisUrl);
    this.queue = new Queue<PasswordResetEmailPayload>('emails', { connection });
    this.worker = new Worker<PasswordResetEmailPayload>(
      'emails',
      async (job) => {
        if (job.name === 'password-reset') {
          await this.mailService.sendPasswordResetEmail(job.data);
        }
      },
      { connection },
    );
    this.worker.on('failed', (job, error) => {
      this.logger.error(
        `Email job ${job?.id ?? 'unknown'} failed: ${error.message}`,
      );
    });
  }

  async onModuleDestroy() {
    await Promise.all([
      this.worker?.close(),
      this.queue?.close(),
    ]);
  }

  async enqueuePasswordResetEmail(payload: PasswordResetEmailPayload) {
    if (!this.queue) {
      await this.mailService.sendPasswordResetEmail(payload);
      return;
    }

    await this.queue.add('password-reset', payload, {
      attempts: 3,
      removeOnComplete: 100,
      removeOnFail: 100,
      backoff: {
        type: 'exponential',
        delay: 1000,
      },
    });
  }

  private parseRedisConnection(redisUrl: string): ConnectionOptions {
    const url = new URL(redisUrl);
    return {
      host: url.hostname,
      port: Number(url.port || '6379'),
      username: url.username || undefined,
      password: url.password || undefined,
      db: url.pathname ? Number(url.pathname.slice(1) || '0') : undefined,
      tls: url.protocol === 'rediss:' ? {} : undefined,
    };
  }
}