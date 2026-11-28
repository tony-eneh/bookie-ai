import { Module } from '@nestjs/common';
import { InsightsService } from './insights.service.js';
import { InsightsController } from './insights.controller.js';
import { FxRatesModule } from '../fx-rates/fx-rates.module.js';

@Module({
  imports: [FxRatesModule],
  providers: [InsightsService],
  controllers: [InsightsController],
  exports: [InsightsService],
})
export class InsightsModule {}
