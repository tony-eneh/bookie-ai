import { Module } from '@nestjs/common';
import { BudgetsService } from './budgets.service.js';
import { BudgetsController } from './budgets.controller.js';
import { FxRatesModule } from '../fx-rates/fx-rates.module.js';

@Module({
  imports: [FxRatesModule],
  controllers: [BudgetsController],
  providers: [BudgetsService],
  exports: [BudgetsService],
})
export class BudgetsModule {}
