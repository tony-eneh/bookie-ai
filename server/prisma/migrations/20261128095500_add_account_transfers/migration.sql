-- AlterTable
ALTER TABLE "transactions" ADD COLUMN     "transfer_account_id" UUID,
ADD COLUMN     "transfer_in" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "transfer_pair_id" UUID;

-- CreateIndex
CREATE INDEX "transactions_transfer_pair_id_idx" ON "transactions"("transfer_pair_id");

-- AddForeignKey
ALTER TABLE "transactions" ADD CONSTRAINT "transactions_transfer_account_id_fkey" FOREIGN KEY ("transfer_account_id") REFERENCES "accounts"("id") ON DELETE SET NULL ON UPDATE CASCADE;
