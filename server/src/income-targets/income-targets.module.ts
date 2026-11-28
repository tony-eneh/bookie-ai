import { Module } from '@nestjs/common';
import { InsightsModule } from '../insights/insights.module.js';
import { IncomeTargetsController } from './income-targets.controller.js';
import { IncomeTargetsService } from './income-targets.service.js';

@Module({
  imports: [InsightsModule],
  controllers: [IncomeTargetsController],
  providers: [IncomeTargetsService],
})
export class IncomeTargetsModule {}
