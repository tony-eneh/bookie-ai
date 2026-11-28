import { Module } from '@nestjs/common';
import { IngestionService } from './ingestion.service.js';
import { IngestionController } from './ingestion.controller.js';
import { FxRatesModule } from '../fx-rates/fx-rates.module.js';
import { LearningModule } from '../learning/learning.module.js';
import { NotificationsModule } from '../notifications/notifications.module.js';

@Module({
  imports: [FxRatesModule, LearningModule, NotificationsModule],
  providers: [IngestionService],
  controllers: [IngestionController],
  exports: [IngestionService],
})
export class IngestionModule {}
