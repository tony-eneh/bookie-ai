import { Global, Module } from '@nestjs/common';
import { MailService } from './mail.service.js';
import { EmailQueueService } from './email-queue.service.js';

@Global()
@Module({
  providers: [MailService, EmailQueueService],
  exports: [MailService, EmailQueueService],
})
export class MailModule {}