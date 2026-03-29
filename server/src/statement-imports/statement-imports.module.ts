import { Module } from '@nestjs/common';
import { StatementImportsService } from './statement-imports.service.js';
import { StatementImportsController } from './statement-imports.controller.js';

@Module({
  controllers: [StatementImportsController],
  providers: [StatementImportsService],
  exports: [StatementImportsService],
})
export class StatementImportsModule {}