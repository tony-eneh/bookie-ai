import type { TransactionType } from '@prisma/client';

/** Built-in categories shared by every user (userId null, isDefault true). */
export const DEFAULT_CATEGORIES: ReadonlyArray<{
  name: string;
  type: TransactionType;
  icon: string;
}> = [
  { name: 'Food & Dining', type: 'EXPENSE', icon: '🍔' },
  { name: 'Groceries', type: 'EXPENSE', icon: '🛒' },
  { name: 'Transport', type: 'EXPENSE', icon: '🚗' },
  { name: 'Fuel', type: 'EXPENSE', icon: '⛽' },
  { name: 'Rent', type: 'EXPENSE', icon: '🏠' },
  { name: 'Utilities', type: 'EXPENSE', icon: '💡' },
  { name: 'Internet', type: 'EXPENSE', icon: '🌐' },
  { name: 'Mobile/Data', type: 'EXPENSE', icon: '📱' },
  { name: 'Healthcare', type: 'EXPENSE', icon: '🏥' },
  { name: 'Education', type: 'EXPENSE', icon: '📚' },
  { name: 'Shopping', type: 'EXPENSE', icon: '🛍️' },
  { name: 'Entertainment', type: 'EXPENSE', icon: '🎬' },
  { name: 'Subscriptions', type: 'EXPENSE', icon: '📺' },
  { name: 'Savings', type: 'EXPENSE', icon: '💰' },
  { name: 'Debt Repayment', type: 'EXPENSE', icon: '💳' },
  { name: 'Gifts/Donations', type: 'EXPENSE', icon: '🎁' },
  { name: 'Family Support', type: 'EXPENSE', icon: '👨‍👩‍👧' },
  { name: 'Business Expense', type: 'EXPENSE', icon: '💼' },
  { name: 'Travel', type: 'EXPENSE', icon: '✈️' },
  { name: 'Miscellaneous', type: 'EXPENSE', icon: '📦' },
  { name: 'Salary', type: 'INCOME', icon: '💵' },
  { name: 'Freelance', type: 'INCOME', icon: '💻' },
  { name: 'Business Income', type: 'INCOME', icon: '🏢' },
  { name: 'Gift Received', type: 'INCOME', icon: '🎀' },
  { name: 'Refund', type: 'INCOME', icon: '↩️' },
  { name: 'Loan Received', type: 'INCOME', icon: '🏦' },
  { name: 'Repayment Received', type: 'INCOME', icon: '🤝' },
  { name: 'Investment Income', type: 'INCOME', icon: '📈' },
  { name: 'Miscellaneous Income', type: 'INCOME', icon: '💫' },
  { name: 'Internal Transfer', type: 'TRANSFER', icon: '🔄' },
  { name: 'Savings Transfer', type: 'TRANSFER', icon: '🏦' },
  { name: 'Wallet Funding', type: 'TRANSFER', icon: '📲' },
  { name: 'Bank Transfer', type: 'TRANSFER', icon: '🏛️' },
];
