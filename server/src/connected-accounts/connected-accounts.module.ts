import { Module } from '@nestjs/common';
import { ConnectedAccountsService } from './connected-accounts.service.js';
import { ConnectedAccountsController } from './connected-accounts.controller.js';

@Module({
  controllers: [ConnectedAccountsController],
  providers: [ConnectedAccountsService],
  exports: [ConnectedAccountsService],
})
export class ConnectedAccountsModule {}