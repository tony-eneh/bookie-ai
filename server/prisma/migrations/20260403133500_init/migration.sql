-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "FxPreference" AS ENUM ('REAL_TIME', 'DAILY_AVERAGE', 'MANUAL_OVERRIDE');

-- CreateEnum
CREATE TYPE "NotificationMode" AS ENUM ('MINIMAL', 'STANDARD', 'PROACTIVE', 'COACH');

-- CreateEnum
CREATE TYPE "FinancialPersonality" AS ENUM ('GENTLE', 'DIRECT', 'COACH_LIKE');

-- CreateEnum
CREATE TYPE "IncomeStyle" AS ENUM ('FIXED_SALARY', 'IRREGULAR', 'BUSINESS', 'MIXED');

-- CreateEnum
CREATE TYPE "AccountType" AS ENUM ('BANK', 'WALLET', 'CASH', 'SAVINGS', 'BUSINESS');

-- CreateEnum
CREATE TYPE "ConnectedAccountStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'REVOKED');

-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('INCOME', 'EXPENSE', 'TRANSFER');

-- CreateEnum
CREATE TYPE "SourceType" AS ENUM ('SMS', 'EMAIL', 'VOICE', 'MANUAL', 'AI_IMPORT');

-- CreateEnum
CREATE TYPE "ClarificationStatus" AS ENUM ('NONE', 'PENDING', 'ANSWERED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "ClarificationItemStatus" AS ENUM ('PENDING', 'ANSWERED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "AnswerSource" AS ENUM ('VOICE', 'TEXT', 'TAP');

-- CreateEnum
CREATE TYPE "BudgetPeriodType" AS ENUM ('WEEKLY', 'MONTHLY');

-- CreateEnum
CREATE TYPE "GoalPriority" AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- CreateEnum
CREATE TYPE "GoalStatus" AS ENUM ('ON_TRACK', 'AT_RISK', 'OFF_TRACK', 'ACHIEVED');

-- CreateEnum
CREATE TYPE "InsightSeverity" AS ENUM ('INFO', 'WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "ReconciliationSource" AS ENUM ('SMS', 'EMAIL', 'MANUAL', 'STATEMENT');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT,
    "full_name" TEXT NOT NULL,
    "country" TEXT,
    "primary_currency" TEXT NOT NULL DEFAULT 'USD',
    "secondary_currencies" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "fx_preference" "FxPreference" NOT NULL DEFAULT 'REAL_TIME',
    "language" TEXT NOT NULL DEFAULT 'en',
    "onboarding_completed" BOOLEAN NOT NULL DEFAULT false,
    "notification_mode" "NotificationMode" NOT NULL DEFAULT 'STANDARD',
    "financial_personality" "FinancialPersonality" NOT NULL DEFAULT 'GENTLE',
    "income_style" "IncomeStyle" NOT NULL DEFAULT 'FIXED_SALARY',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "accounts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "type" "AccountType" NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "current_balance" DECIMAL(19,4) NOT NULL DEFAULT 0,
    "last_reconciled_balance" DECIMAL(19,4),
    "last_reconciled_at" TIMESTAMP(3),
    "is_primary" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "connected_accounts" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "provider_type" TEXT NOT NULL,
    "provider_email" TEXT NOT NULL,
    "access_token" TEXT,
    "refresh_token" TEXT,
    "scopes" TEXT,
    "status" "ConnectedAccountStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "connected_accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transactions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "type" "TransactionType" NOT NULL,
    "amount" DECIMAL(19,4) NOT NULL,
    "currency" TEXT NOT NULL,
    "original_currency" TEXT,
    "converted_amount" DECIMAL(19,4),
    "fx_rate_used" DECIMAL(19,8),
    "occurred_at" TIMESTAMP(3) NOT NULL,
    "description" TEXT,
    "merchant_name" TEXT,
    "counterparty" TEXT,
    "category_id" UUID,
    "subcategory" TEXT,
    "source_type" "SourceType" NOT NULL,
    "source_ref" TEXT,
    "raw_content" TEXT,
    "parse_confidence" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "category_confidence" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "needs_clarification" BOOLEAN NOT NULL DEFAULT false,
    "clarification_status" "ClarificationStatus" NOT NULL DEFAULT 'NONE',
    "note" TEXT,
    "is_recurring_guess" BOOLEAN NOT NULL DEFAULT false,
    "balance_after_transaction" DECIMAL(19,4),
    "is_balance_source" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "categories" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "name" TEXT NOT NULL,
    "type" "TransactionType" NOT NULL,
    "icon" TEXT NOT NULL DEFAULT '📦',
    "color" TEXT,
    "is_default" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clarifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "transaction_id" UUID NOT NULL,
    "question_text" TEXT NOT NULL,
    "status" "ClarificationItemStatus" NOT NULL,
    "answer_text" TEXT,
    "answer_source" "AnswerSource",
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved_at" TIMESTAMP(3),

    CONSTRAINT "clarifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "budgets" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "category_id" UUID,
    "period_type" "BudgetPeriodType" NOT NULL,
    "amount" DECIMAL(19,4) NOT NULL,
    "currency" TEXT NOT NULL,
    "start_date" TIMESTAMP(3) NOT NULL,
    "end_date" TIMESTAMP(3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "budgets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "goals" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "target_amount" DECIMAL(19,4) NOT NULL,
    "current_amount" DECIMAL(19,4) NOT NULL DEFAULT 0,
    "target_currency" TEXT NOT NULL DEFAULT 'USD',
    "target_date" TIMESTAMP(3) NOT NULL,
    "priority" "GoalPriority" NOT NULL DEFAULT 'MEDIUM',
    "linked_budget_strategy" TEXT,
    "monthly_required_amount" DECIMAL(19,4),
    "required_monthly_income" DECIMAL(19,4),
    "status" "GoalStatus" NOT NULL DEFAULT 'ON_TRACK',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "goals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "goal_contributions" (
    "id" UUID NOT NULL,
    "goal_id" UUID NOT NULL,
    "transaction_id" UUID,
    "amount" DECIMAL(19,4) NOT NULL,
    "currency" TEXT NOT NULL,
    "converted_amount" DECIMAL(19,4),
    "contribution_date" TIMESTAMP(3) NOT NULL,
    "source_type" TEXT NOT NULL,

    CONSTRAINT "goal_contributions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "insights" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "insight_type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "severity" "InsightSeverity" NOT NULL DEFAULT 'INFO',
    "period_start" TIMESTAMP(3),
    "period_end" TIMESTAMP(3),
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "insights_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "type" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "read_at" TIMESTAMP(3),
    "action_payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "merchant_aliases" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "match_pattern" TEXT NOT NULL,
    "merchant_name" TEXT,
    "category_id" UUID NOT NULL,
    "transaction_type" TEXT,
    "confidence_boost" DOUBLE PRECISION NOT NULL DEFAULT 0.1,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "merchant_aliases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "income_targets" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "target_monthly_income" DECIMAL(19,4) NOT NULL,
    "effective_from" TIMESTAMP(3) NOT NULL,
    "effective_to" TIMESTAMP(3),
    "reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "income_targets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "account_reconciliations" (
    "id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "balance" DECIMAL(19,4) NOT NULL,
    "source" "ReconciliationSource" NOT NULL,
    "drift_amount" DECIMAL(19,4),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "account_reconciliations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "statement_imports" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "account_id" UUID NOT NULL,
    "source" TEXT NOT NULL,
    "file_type" TEXT NOT NULL,
    "parsed_successfully" BOOLEAN NOT NULL DEFAULT false,
    "transactions_imported" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "statement_imports_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "scenario_simulations" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "input_payload" JSONB NOT NULL,
    "result_payload" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scenario_simulations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fx_rates" (
    "id" UUID NOT NULL,
    "base_currency" TEXT NOT NULL,
    "target_currency" TEXT NOT NULL,
    "rate" DECIMAL(19,8) NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'api',
    "fetched_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "fx_rates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "accounts_user_id_idx" ON "accounts"("user_id");

-- CreateIndex
CREATE INDEX "connected_accounts_user_id_idx" ON "connected_accounts"("user_id");

-- CreateIndex
CREATE INDEX "transactions_user_id_idx" ON "transactions"("user_id");

-- CreateIndex
CREATE INDEX "transactions_account_id_idx" ON "transactions"("account_id");

-- CreateIndex
CREATE INDEX "transactions_category_id_idx" ON "transactions"("category_id");

-- CreateIndex
CREATE INDEX "transactions_occurred_at_idx" ON "transactions"("occurred_at");

-- CreateIndex
CREATE INDEX "categories_user_id_idx" ON "categories"("user_id");

-- CreateIndex
CREATE INDEX "clarifications_user_id_idx" ON "clarifications"("user_id");

-- CreateIndex
CREATE INDEX "clarifications_transaction_id_idx" ON "clarifications"("transaction_id");

-- CreateIndex
CREATE INDEX "budgets_user_id_idx" ON "budgets"("user_id");

-- CreateIndex
CREATE INDEX "budgets_category_id_idx" ON "budgets"("category_id");

-- CreateIndex
CREATE INDEX "goals_user_id_idx" ON "goals"("user_id");

-- CreateIndex
CREATE INDEX "goal_contributions_goal_id_idx" ON "goal_contributions"("goal_id");

-- CreateIndex
CREATE INDEX "goal_contributions_transaction_id_idx" ON "goal_contributions"("transaction_id");

-- CreateIndex
CREATE INDEX "insights_user_id_idx" ON "insights"("user_id");

-- CreateIndex
CREATE INDEX "notifications_user_id_idx" ON "notifications"("user_id");

-- CreateIndex
CREATE INDEX "merchant_aliases_user_id_idx" ON "merchant_aliases"("user_id");

-- CreateIndex
CREATE INDEX "merchant_aliases_category_id_idx" ON "merchant_aliases"("category_id");

-- CreateIndex
CREATE INDEX "income_targets_user_id_idx" ON "income_targets"("user_id");

-- CreateIndex
CREATE INDEX "account_reconciliations_account_id_idx" ON "account_reconciliations"("account_id");

-- CreateIndex
CREATE INDEX "statement_imports_user_id_idx" ON "statement_imports"("user_id");

-- CreateIndex
CREATE INDEX "statement_imports_account_id_idx" ON "statement_imports"("account_id");

-- CreateIndex
CREATE INDEX "scenario_simulations_user_id_idx" ON "scenario_simulations"("user_id");

-- CreateIndex
CREATE INDEX "fx_rates_base_currency_target_currency_idx" ON "fx_rates"("base_currency", "target_currency");

-- CreateIndex
CREATE UNIQUE INDEX "fx_rates_base_currency_target_currency_key" ON "fx_rates"("base_currency", "target_currency");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_key" ON "refresh_tokens"("token");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- AddForeignKey
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "connected_accounts" ADD CONSTRAINT "connected_accounts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "categories" ADD CONSTRAINT "categories_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clarifications" ADD CONSTRAINT "clarifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clarifications" ADD CONSTRAINT "clarifications_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "transactions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "budgets" ADD CONSTRAINT "budgets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "budgets" ADD CONSTRAINT "budgets_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goals" ADD CONSTRAINT "goals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goal_contributions" ADD CONSTRAINT "goal_contributions_goal_id_fkey" FOREIGN KEY ("goal_id") REFERENCES "goals"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "goal_contributions" ADD CONSTRAINT "goal_contributions_transaction_id_fkey" FOREIGN KEY ("transaction_id") REFERENCES "transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "insights" ADD CONSTRAINT "insights_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "merchant_aliases" ADD CONSTRAINT "merchant_aliases_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "merchant_aliases" ADD CONSTRAINT "merchant_aliases_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "income_targets" ADD CONSTRAINT "income_targets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "account_reconciliations" ADD CONSTRAINT "account_reconciliations_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_imports" ADD CONSTRAINT "statement_imports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "statement_imports" ADD CONSTRAINT "statement_imports_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "scenario_simulations" ADD CONSTRAINT "scenario_simulations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

