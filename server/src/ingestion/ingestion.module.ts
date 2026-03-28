import { Module } from '@nestjs/common';
import { IngestionService } from './ingestion.service.js';
import { IngestionController } from './ingestion.controller.js';

@Module({
  providers: [IngestionService],
  controllers: [IngestionController],
  exports: [IngestionService],
})
export class IngestionModule {}
