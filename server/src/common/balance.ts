/**
 * How a transaction moves its account's balance. Income adds, spending
 * subtracts; a transfer subtracts on the outgoing leg and adds on the
 * incoming one (transferIn).
 */
export function balanceDelta(
  type: string,
  amount: number,
  transferIn = false,
): number {
  if (type === 'INCOME') return amount;
  if (type === 'TRANSFER' && transferIn) return amount;
  return -amount;
}
