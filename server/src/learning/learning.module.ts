import { Module } from '@nestjs/common';
import { MerchantAliasService } from './merchant-alias.service.js';

@Module({
  providers: [MerchantAliasService],
  exports: [MerchantAliasService],
})
export class LearningModule {}
