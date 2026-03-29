import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module.js';
import { AuthModule } from './auth/auth.module.js';
import { UsersModule } from './users/users.module.js';
import { AccountsModule } from './accounts/accounts.module.js';
import { CategoriesModule } from './categories/categories.module.js';
import { TransactionsModule } from './transactions/transactions.module.js';
import { FxRatesModule } from './fx-rates/fx-rates.module.js';
import { ClarificationsModule } from './clarifications/clarifications.module.js';
import { BudgetsModule } from './budgets/budgets.module.js';
import { GoalsModule } from './goals/goals.module.js';
import { AiModule } from './ai/ai.module.js';
import { IngestionModule } from './ingestion/ingestion.module.js';
import { InsightsModule } from './insights/insights.module.js';
import { AssistantModule } from './assistant/assistant.module.js';
import { ConnectedAccountsModule } from './connected-accounts/connected-accounts.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';
import { StatementImportsModule } from './statement-imports/statement-imports.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AiModule,
    AuthModule,
    UsersModule,
    AccountsModule,
    CategoriesModule,
    TransactionsModule,
    FxRatesModule,
    ClarificationsModule,
    BudgetsModule,
    GoalsModule,
    IngestionModule,
    InsightsModule,
    AssistantModule,
    ConnectedAccountsModule,
    NotificationsModule,
    StatementImportsModule,
  ],
})
export class AppModule {}
