// Parses payloads captured from the real API (local server, mock AI mode) to
// catch field-name drift between the app and the server. When a server
// response changes, update the fixture here from a real response.
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
}
