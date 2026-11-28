// Parses payloads captured from the real API (local server, mock AI mode) to
// catch field-name drift between the app and the server. When a server
// response changes, update the fixture here from a real response.
import 'package:bookie_ai/data/models/budget_model.dart';
import 'package:bookie_ai/data/models/goal_model.dart';
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
}
