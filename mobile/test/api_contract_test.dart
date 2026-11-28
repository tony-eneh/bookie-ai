// Parses payloads captured from the real API (local server, mock AI mode) to
// catch field-name drift between the app and the server. When a server
// response changes, update the fixture here from a real response.
import 'package:bookie_ai/data/models/budget_model.dart';
import 'package:bookie_ai/data/models/goal_model.dart';
import 'package:bookie_ai/data/models/insight_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GoalProjection reads GET /goals/:id/projection', () {
    final p = GoalProjection.fromJson({
      'monthsRemaining': 6,
      'requiredMonthlySavings': 633166.67,
      'requiredMonthlyIncome': 778500,
      'currentPace': 1000,
      'projectedCompletionDate': '2027-06-28T01:56:42.205Z',
      'status': 'OFF_TRACK',
      'coaching': "At your current pace, you'll miss your target date.",
    });
    expect(p.currentMonthlyPace, 1000);
    expect(p.requiredMonthlyAmount, 633166.67);
    expect(p.requiredMonthlyIncome, 778500);
    expect(p.projectedCompletionDate, isNotNull);
  });

  test('Budget reads nested progress from GET /budgets', () {
    final b = Budget.fromJson({
      'id': '776ee4c4',
      'name': 'Shopping Budget',
      'categoryId': 'be093769',
      'periodType': 'MONTHLY',
      'amount': '100000',
      'currency': 'NGN',
      'startDate': '2026-10-31T15:00:00.000Z',
      'endDate': null,
      'isActive': true,
      'createdAt': '2026-11-28T01:41:20.183Z',
      'progress': {
        'amountUsed': 73000,
        'amountRemaining': 27000,
        'percentageUsed': 73,
        'isOverspent': false,
        'projectedOverspend': 0,
      },
    });
    expect(b.amount, 100000);
    expect(b.amountUsed, 73000);
    expect(b.percentageUsed, 73);
    expect(b.isOverspent, isFalse);
  });

  group('GET /insights/dashboard', () {
    final payload = {
      'totalIncome': 4000000,
      'totalExpenses': 436000,
      'netCashFlow': 3564000,
      'budgetProgress': [
        {
          'budgetId': 'ab04d7b9',
          'name': 'Food Budget',
          'categoryName': 'Food & Dining',
          'currency': 'KRW',
          'budgetAmount': 400000,
          'spent': 112500,
          'remaining': 287500,
          'percentageUsed': 28.1,
          'isOverspent': false,
        },
      ],
      'topCategories': [
        {'name': 'Food & Dining', 'icon': '🍔', 'total': 112500},
      ],
      'pendingClarifications': 2,
      'goalProgress': [
        {
          'goalId': 'd081958c',
          'title': 'Emergency Fund',
          'targetAmount': 5000000,
          'currentAmount': 1201000,
          'percentage': 24,
          'status': 'ON_TRACK',
          'targetDate': '2027-05-28T01:41:20.205Z',
        },
      ],
      'recentTransactions': [],
      'smartInsights': [
        {
          'type': 'savings',
          'message': "You're saving 89.1% of your income this month.",
          'severity': 'INFO',
        },
      ],
    };

    test('parses server field names', () {
      final d = DashboardData.fromJson({
        ...payload,
        'currency': 'KRW',
        'totalBalance': 3494705,
      });
      expect(d.currency, 'KRW');
      expect(d.totalBalance, 3494705);
      expect(d.budgetProgress.single.amount, 400000);
      expect(d.budgetProgress.single.currency, 'KRW');
      expect(d.budgetProgress.single.used, 112500);
      expect(d.budgetProgress.single.percentage, 28.1);
      expect(d.topCategories.single.amount, 112500);
      expect(d.goalProgress.single.percentage, 24);
      expect(d.insights.single, startsWith("You're saving"));
      expect(d.pendingClarifications, 2);
    });

    test('survives the Hive cache round trip', () {
      final cached = DashboardData.fromJson(
        DashboardData.fromJson(payload).toJson(),
      );
      expect(cached.budgetProgress.single.used, 112500);
      expect(cached.topCategories.single.amount, 112500);
      expect(cached.insights, hasLength(1));
    });
  });

  test('WeeklySummary reads GET /insights/weekly', () {
    final w = WeeklySummary.fromJson({
      'income': 100000,
      'expenses': 225200,
      'net': -125200,
      'topCategory': {'name': 'Groceries', 'amount': 67000},
      'pendingClarifications': 2,
      'vsPreviousWeek': {
        'incomeChange': -400000,
        'expenseChange': 127400,
      },
    });
    expect(w.totalIncome, 100000);
    expect(w.totalExpenses, 225200);
    expect(w.netCashFlow, -125200);
    expect(w.incomeChange, -400000);
    expect(w.topCategories.single.name, 'Groceries');
  });
}
