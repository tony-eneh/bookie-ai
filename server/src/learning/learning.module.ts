import { Module } from '@nestjs/common';
import { MerchantAliasService } from './merchant-alias.service.js';
import { RecurringService } from './recurring.service.js';

@Module({
  providers: [MerchantAliasService, RecurringService],
  exports: [MerchantAliasService, RecurringService],
})
export class LearningModule {}
