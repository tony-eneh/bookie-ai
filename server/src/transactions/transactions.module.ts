import { Module } from '@nestjs/common';
import { TransactionsService } from './transactions.service.js';
import { TransactionsController } from './transactions.controller.js';
import { LearningModule } from '../learning/learning.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [LearningModule, NotificationsModule],
  controllers: [TransactionsController],
  providers: [TransactionsService],
  exports: [TransactionsService],
})
export class TransactionsModule {}
