import { Module } from '@nestjs/common';
import { ClarificationsService } from './clarifications.service.js';
import { ClarificationsController } from './clarifications.controller.js';
import { LearningModule } from '../learning/learning.module.js';

@Module({
  imports: [LearningModule],
  controllers: [ClarificationsController],
  providers: [ClarificationsService],
  exports: [ClarificationsService],
})
export class ClarificationsModule {}
