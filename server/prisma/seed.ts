import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL must be set before running the seed script');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
});

function getBalanceDelta(type: 'INCOME' | 'EXPENSE' | 'TRANSFER', amount: number) {
  if (type === 'INCOME') {
    return amount;
  }

  return -amount;
}

async function main() {
  console.log('🌱 Seeding BookieAI database...');

  // Clean existing data
  await prisma.$transaction([
    prisma.notification.deleteMany(),
    prisma.insight.deleteMany(),
    prisma.scenarioSimulation.deleteMany(),
    prisma.statementImport.deleteMany(),
    prisma.goalContribution.deleteMany(),
    prisma.clarification.deleteMany(),
    prisma.merchantAlias.deleteMany(),
    prisma.accountReconciliation.deleteMany(),
    prisma.transaction.deleteMany(),
    prisma.budget.deleteMany(),
    prisma.goal.deleteMany(),
    prisma.incomeTarget.deleteMany(),
    prisma.fxRate.deleteMany(),
    prisma.account.deleteMany(),
    prisma.category.deleteMany(),
    prisma.connectedAccount.deleteMany(),
    prisma.refreshToken.deleteMany(),
    prisma.user.deleteMany(),
  ]);

  // Create demo user
  const passwordHash = await bcrypt.hash('demo123456', 10);
  const user = await prisma.user.create({
    data: {
      email: 'demo@bookieai.com',
      passwordHash,
      fullName: 'Demo User',
      country: 'KR',
      primaryCurrency: 'KRW',
      secondaryCurrencies: ['NGN', 'USD'],
      fxPreference: 'REAL_TIME',
      language: 'en',
      onboardingCompleted: true,
      notificationMode: 'PROACTIVE',
      financialPersonality: 'COACH_LIKE',
      incomeStyle: 'MIXED',
    },
  });
  console.log('✅ Demo user created:', user.email);

  // Create accounts
  const kookmin = await prisma.account.create({
    data: {
      userId: user.id,
      name: 'Kookmin Bank',
      type: 'BANK',
      currency: 'KRW',
      currentBalance: 0,
      isPrimary: true,
    },
  });
  const gtbank = await prisma.account.create({
    data: {
      userId: user.id,
      name: 'GTBank Nigeria',
      type: 'BANK',
      currency: 'NGN',
      currentBalance: 0,
    },
  });
  const cashWallet = await prisma.account.create({
    data: {
      userId: user.id,
      name: 'Cash Wallet',
      type: 'CASH',
      currency: 'KRW',
      currentBalance: 0,
    },
  });
  console.log('✅ 3 accounts created');

  // Seed default categories
  const expenseCategories = [
    { name: 'Food & Dining', icon: '🍔' },
    { name: 'Groceries', icon: '🛒' },
    { name: 'Transport', icon: '🚗' },
    { name: 'Fuel', icon: '⛽' },
    { name: 'Rent', icon: '🏠' },
    { name: 'Utilities', icon: '💡' },
    { name: 'Internet', icon: '🌐' },
    { name: 'Mobile/Data', icon: '📱' },
    { name: 'Healthcare', icon: '🏥' },
    { name: 'Education', icon: '📚' },
    { name: 'Shopping', icon: '🛍️' },
    { name: 'Entertainment', icon: '🎬' },
    { name: 'Subscriptions', icon: '📺' },
    { name: 'Savings', icon: '💰' },
    { name: 'Debt Repayment', icon: '💳' },
    { name: 'Gifts/Donations', icon: '🎁' },
    { name: 'Family Support', icon: '👨‍👩‍👧' },
    { name: 'Business Expense', icon: '💼' },
    { name: 'Travel', icon: '✈️' },
    { name: 'Miscellaneous', icon: '📦' },
  ];
  const incomeCategories = [
    { name: 'Salary', icon: '💵' },
    { name: 'Freelance', icon: '💻' },
    { name: 'Business Income', icon: '🏢' },
    { name: 'Gift Received', icon: '🎀' },
    { name: 'Refund', icon: '↩️' },
    { name: 'Loan Received', icon: '🏦' },
    { name: 'Repayment Received', icon: '🤝' },
    { name: 'Investment Income', icon: '📈' },
    { name: 'Miscellaneous Income', icon: '💫' },
  ];
  const transferCategories = [
    { name: 'Internal Transfer', icon: '🔄' },
    { name: 'Savings Transfer', icon: '🏦' },
    { name: 'Wallet Funding', icon: '📲' },
    { name: 'Bank Transfer', icon: '🏛️' },
  ];

  const categories: Record<string, { id: string }> = {};
  for (const cat of expenseCategories) {
    const c = await prisma.category.create({
      data: { name: cat.name, type: 'EXPENSE', icon: cat.icon, isDefault: true },
    });
    categories[cat.name] = c;
  }
  for (const cat of incomeCategories) {
    const c = await prisma.category.create({
      data: { name: cat.name, type: 'INCOME', icon: cat.icon, isDefault: true },
    });
    categories[cat.name] = c;
  }
  for (const cat of transferCategories) {
    const c = await prisma.category.create({
      data: { name: cat.name, type: 'TRANSFER', icon: cat.icon, isDefault: true },
    });
    categories[cat.name] = c;
  }
  console.log('✅ 33 default categories created');

  // Helper to get a date N days ago
  const daysAgo = (n: number) => {
    const d = new Date();
    d.setDate(d.getDate() - n);
    return d;
  };

  // Create transactions
  const txns = [
    // Salary credits
    { accountId: kookmin.id, type: 'INCOME' as const, amount: 3200000, currency: 'KRW', description: 'Monthly Salary - March', merchantName: 'Samsung Electronics', categoryName: 'Salary', occurredAt: daysAgo(25), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'INCOME' as const, amount: 3200000, currency: 'KRW', description: 'Monthly Salary - February', merchantName: 'Samsung Electronics', categoryName: 'Salary', occurredAt: daysAgo(55), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'INCOME' as const, amount: 3200000, currency: 'KRW', description: 'Monthly Salary - January', merchantName: 'Samsung Electronics', categoryName: 'Salary', occurredAt: daysAgo(85), sourceType: 'SMS' as const },
    // Freelance income
    { accountId: gtbank.id, type: 'INCOME' as const, amount: 350000, currency: 'NGN', description: 'Freelance payment - Web Design', merchantName: 'Upwork', categoryName: 'Freelance', occurredAt: daysAgo(10), sourceType: 'EMAIL' as const },
    { accountId: gtbank.id, type: 'INCOME' as const, amount: 200000, currency: 'NGN', description: 'Freelance payment - Logo Design', merchantName: 'Fiverr', categoryName: 'Freelance', occurredAt: daysAgo(20), sourceType: 'EMAIL' as const },
    // Food & Dining
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 15000, currency: 'KRW', description: 'Lunch at Korean BBQ', merchantName: 'Gangnam BBQ', categoryName: 'Food & Dining', occurredAt: daysAgo(1), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 8500, currency: 'KRW', description: 'Coffee and pastry', merchantName: 'Starbucks Gangnam', categoryName: 'Food & Dining', occurredAt: daysAgo(2), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 32000, currency: 'KRW', description: 'Dinner with friends', merchantName: 'Itaewon Grill', categoryName: 'Food & Dining', occurredAt: daysAgo(5), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 12000, currency: 'KRW', description: 'Quick lunch', merchantName: 'Kimbap Heaven', categoryName: 'Food & Dining', occurredAt: daysAgo(8), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 45000, currency: 'KRW', description: 'Weekend dinner', merchantName: 'Myeongdong Restaurant', categoryName: 'Food & Dining', occurredAt: daysAgo(12), sourceType: 'VOICE' as const },
    // Transport
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 1350, currency: 'KRW', description: 'Subway ride', merchantName: 'Seoul Metro', categoryName: 'Transport', occurredAt: daysAgo(1), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 15000, currency: 'KRW', description: 'Taxi to airport', merchantName: 'Kakao Taxi', categoryName: 'Transport', occurredAt: daysAgo(7), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 1350, currency: 'KRW', description: 'Bus fare', merchantName: 'Seoul Bus', categoryName: 'Transport', occurredAt: daysAgo(3), sourceType: 'SMS' as const },
    // Shopping (NGN)
    { accountId: gtbank.id, type: 'EXPENSE' as const, amount: 45000, currency: 'NGN', description: 'Clothes shopping', merchantName: 'Shoprite', categoryName: 'Shopping', occurredAt: daysAgo(4), sourceType: 'SMS' as const },
    { accountId: gtbank.id, type: 'EXPENSE' as const, amount: 28000, currency: 'NGN', description: 'Electronics accessories', merchantName: 'Jumia', categoryName: 'Shopping', occurredAt: daysAgo(15), sourceType: 'EMAIL' as const },
    // Subscriptions
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 14900, currency: 'KRW', description: 'Netflix subscription', merchantName: 'Netflix', categoryName: 'Subscriptions', occurredAt: daysAgo(6), sourceType: 'SMS' as const },
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 10900, currency: 'KRW', description: 'Spotify Premium', merchantName: 'Spotify', categoryName: 'Subscriptions', occurredAt: daysAgo(6), sourceType: 'SMS' as const },
    // Utilities
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 85000, currency: 'KRW', description: 'Electricity bill', merchantName: 'KEPCO', categoryName: 'Utilities', occurredAt: daysAgo(18), sourceType: 'SMS' as const },
    // Groceries
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 67000, currency: 'KRW', description: 'Weekly groceries', merchantName: 'E-Mart', categoryName: 'Groceries', occurredAt: daysAgo(3), sourceType: 'SMS' as const },
    // Ambiguous transactions (need clarification)
    { accountId: kookmin.id, type: 'EXPENSE' as const, amount: 55000, currency: 'KRW', description: 'POS Purchase at unknown vendor', needsClarification: true, occurredAt: daysAgo(2), sourceType: 'SMS' as const, parseConfidence: 0.4 },
    { accountId: gtbank.id, type: 'INCOME' as const, amount: 150000, currency: 'NGN', description: 'Transfer from Emeka', needsClarification: true, occurredAt: daysAgo(9), sourceType: 'SMS' as const, parseConfidence: 0.5 },
    // Internal transfer
    { accountId: kookmin.id, type: 'TRANSFER' as const, amount: 100000, currency: 'KRW', description: 'Transfer to cash wallet', categoryName: 'Internal Transfer', occurredAt: daysAgo(14), sourceType: 'MANUAL' as const },
  ];

  const targetEndingBalances = new Map<string, number>([
    [kookmin.id, 2500000],
    [gtbank.id, 850000],
    [cashWallet.id, 150000],
  ]);
  const netDeltas = new Map<string, number>([
    [kookmin.id, 0],
    [gtbank.id, 0],
    [cashWallet.id, 0],
  ]);

  for (const txn of txns) {
    const currentDelta = netDeltas.get(txn.accountId) ?? 0;
    netDeltas.set(
      txn.accountId,
      currentDelta + getBalanceDelta(txn.type, txn.amount),
    );
  }

  const openingBalances = new Map<string, number>();
  for (const [accountId, endingBalance] of targetEndingBalances.entries()) {
    openingBalances.set(accountId, endingBalance - (netDeltas.get(accountId) ?? 0));
  }

  await prisma.$transaction(
    [kookmin.id, gtbank.id, cashWallet.id].map((accountId) =>
      prisma.account.update({
        where: { id: accountId },
        data: { currentBalance: openingBalances.get(accountId) ?? 0 },
      }),
    ),
  );

  const runningBalances = new Map(openingBalances);
  const sortedTxns = [...txns].sort(
    (left, right) => left.occurredAt.getTime() - right.occurredAt.getTime(),
  );

  const createdTxns: { id: string; description: string | null; needsClarification: boolean }[] = [];
  for (const txn of sortedTxns) {
    const categoryId = txn.categoryName ? categories[txn.categoryName]?.id : undefined;
    const nextBalance =
      (runningBalances.get(txn.accountId) ?? 0) +
      getBalanceDelta(txn.type, txn.amount);
    runningBalances.set(txn.accountId, nextBalance);

    const t = await prisma.transaction.create({
      data: {
        userId: user.id,
        accountId: txn.accountId,
        type: txn.type,
        amount: txn.amount,
        currency: txn.currency,
        originalCurrency: txn.currency,
        occurredAt: txn.occurredAt,
        description: txn.description,
        merchantName: txn.merchantName || null,
        categoryId: categoryId || null,
        sourceType: txn.sourceType,
        parseConfidence: txn.parseConfidence || 1.0,
        categoryConfidence: categoryId ? 0.9 : 0.3,
        needsClarification: txn.needsClarification || false,
        clarificationStatus: txn.needsClarification ? 'PENDING' : 'NONE',
        balanceAfterTransaction: nextBalance,
      },
    });
    createdTxns.push(t);
  }
  console.log(`✅ ${createdTxns.length} transactions created`);

  await prisma.$transaction(
    [kookmin.id, gtbank.id, cashWallet.id].map((accountId) =>
      prisma.account.update({
        where: { id: accountId },
        data: { currentBalance: runningBalances.get(accountId) ?? 0 },
      }),
    ),
  );

  // Create clarifications for ambiguous transactions
  const ambiguousTxns = createdTxns.filter((t) => t.needsClarification);
  for (const txn of ambiguousTxns) {
    await prisma.clarification.create({
      data: {
        userId: user.id,
        transactionId: txn.id,
        questionText:
          txn.description?.includes('POS')
            ? 'I noticed a ₩55,000 purchase. Was that shopping, food, entertainment, or something else?'
            : 'You received ₦150,000 from Emeka. Was that salary, a gift, repayment, or business income?',
        status: 'PENDING',
      },
    });
  }
  console.log('✅ 2 clarifications created');

  // Create budgets
  await prisma.budget.create({
    data: {
      userId: user.id,
      name: 'Food Budget',
      categoryId: categories['Food & Dining'].id,
      periodType: 'MONTHLY',
      amount: 400000,
      currency: 'KRW',
      startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    },
  });
  await prisma.budget.create({
    data: {
      userId: user.id,
      name: 'Transport Budget',
      categoryId: categories['Transport'].id,
      periodType: 'MONTHLY',
      amount: 150000,
      currency: 'KRW',
      startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    },
  });
  await prisma.budget.create({
    data: {
      userId: user.id,
      name: 'Shopping Budget',
      categoryId: categories['Shopping'].id,
      periodType: 'MONTHLY',
      amount: 100000,
      currency: 'NGN',
      startDate: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
    },
  });
  console.log('✅ 3 budgets created');

  // Create goals
  const nextYear = new Date();
  nextYear.setFullYear(nextYear.getFullYear() + 1);
  const sixMonths = new Date();
  sixMonths.setMonth(sixMonths.getMonth() + 6);

  await prisma.goal.create({
    data: {
      userId: user.id,
      title: 'Buy a Car',
      description: 'Save up for a new Hyundai Tucson',
      targetAmount: 15000000,
      currentAmount: 2800000,
      targetCurrency: 'KRW',
      targetDate: nextYear,
      priority: 'HIGH',
      monthlyRequiredAmount: 1016667,
      status: 'AT_RISK',
    },
  });
  await prisma.goal.create({
    data: {
      userId: user.id,
      title: 'Emergency Fund',
      description: 'Build 3-month emergency savings',
      targetAmount: 5000000,
      currentAmount: 1200000,
      targetCurrency: 'KRW',
      targetDate: sixMonths,
      priority: 'MEDIUM',
      monthlyRequiredAmount: 633333,
      status: 'ON_TRACK',
    },
  });
  console.log('✅ 2 goals created');

  // Create notifications
  const notifs = [
    { type: 'transaction_detected', title: 'New Transaction', body: 'We detected a ₩15,000 expense at Gangnam BBQ' },
    { type: 'clarification_needed', title: 'Help Us Categorize', body: 'A ₩55,000 purchase needs your input' },
    { type: 'budget_warning', title: 'Budget Alert', body: "You've used 75% of your Food budget this month" },
    { type: 'goal_risk', title: 'Goal Update', body: 'Your car savings goal is at risk. Consider increasing monthly savings.' },
    { type: 'weekly_summary', title: 'Weekly Summary', body: 'Your week: ₩112,500 spent, ₩3,200,000 earned. Tap to see details.' },
  ];
  for (const n of notifs) {
    await prisma.notification.create({
      data: { userId: user.id, type: n.type, title: n.title, body: n.body },
    });
  }
  console.log('✅ 5 notifications created');

  // Create FX rates
  const rates = [
    { baseCurrency: 'USD', targetCurrency: 'KRW', rate: 1350.0 },
    { baseCurrency: 'USD', targetCurrency: 'NGN', rate: 1550.0 },
    { baseCurrency: 'KRW', targetCurrency: 'NGN', rate: 1.148 },
    { baseCurrency: 'KRW', targetCurrency: 'USD', rate: 0.000741 },
    { baseCurrency: 'NGN', targetCurrency: 'KRW', rate: 0.871 },
    { baseCurrency: 'NGN', targetCurrency: 'USD', rate: 0.000645 },
  ];
  for (const r of rates) {
    await prisma.fxRate.create({
      data: { ...r, rate: r.rate, source: 'seed', fetchedAt: new Date() },
    });
  }
  console.log('✅ FX rates created');

  // Create income target
  await prisma.incomeTarget.create({
    data: {
      userId: user.id,
      title: 'Monthly Income Goal',
      targetMonthlyIncome: 3500000,
      effectiveFrom: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
      reason: 'Need this income level to meet car savings goal and living expenses',
    },
  });
  console.log('✅ Income target created');

  console.log('\n🎉 Seeding complete! Login with demo@bookieai.com / demo123456');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
