import { Module } from '@nestjs/common';
import { FxRatesModule } from '../fx-rates/fx-rates.module.js';
import { GoalsModule } from '../goals/goals.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';
import { JobsController } from './jobs.controller.js';
import { JobsService } from './jobs.service.js';

@Module({
  imports: [FxRatesModule, GoalsModule, NotificationsModule],
  controllers: [JobsController],
  providers: [JobsService],
})
export class JobsModule {}
