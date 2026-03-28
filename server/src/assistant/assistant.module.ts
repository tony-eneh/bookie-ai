import { Module } from '@nestjs/common';
import { AssistantService } from './assistant.service.js';
import { AssistantController } from './assistant.controller.js';

@Module({
  providers: [AssistantService],
  controllers: [AssistantController],
  exports: [AssistantService],
})
export class AssistantModule {}
