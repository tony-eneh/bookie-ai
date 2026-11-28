import { Module } from '@nestjs/common';
import { AssistantService } from './assistant.service.js';
import { AssistantController } from './assistant.controller.js';
import { InsightsModule } from '../insights/insights.module.js';

@Module({
  imports: [InsightsModule],
  providers: [AssistantService],
  controllers: [AssistantController],
  exports: [AssistantService],
})
export class AssistantModule {}
