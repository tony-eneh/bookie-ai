import { Module } from '@nestjs/common';
import { ClarificationsService } from './clarifications.service.js';
import { ClarificationsController } from './clarifications.controller.js';

@Module({
  controllers: [ClarificationsController],
  providers: [ClarificationsService],
  exports: [ClarificationsService],
})
export class ClarificationsModule {}
