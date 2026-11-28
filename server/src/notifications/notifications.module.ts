import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service.js';
import { NotificationsController } from './notifications.controller.js';
import { NotificationTriggersService } from './notification-triggers.service.js';
import { BudgetsModule } from '../budgets/budgets.module.js';

@Module({
  imports: [BudgetsModule],
  providers: [NotificationsService, NotificationTriggersService],
  controllers: [NotificationsController],
  exports: [NotificationsService, NotificationTriggersService],
})
export class NotificationsModule {}
