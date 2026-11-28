import 'package:bookie_ai/data/models/category_model.dart';
import 'package:bookie_ai/features/clarifications/clarifications_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Category _c(String name) => Category(
      id: name,
      name: name,
      type: 'EXPENSE',
      icon: '',
      isDefault: true,
    );

void main() {
  test('categories named in the question come first', () {
    final ranked = rankCategoriesForQuestion(
      'Was that shopping, food, entertainment, or something else?',
      [
        _c('Debt Repayment'),
        _c('Entertainment'),
        _c('Food & Dining'),
        _c('Shopping'),
        _c('Fuel')
      ],
    ).map((c) => c.name).toList();
    expect(ranked.take(3),
        containsAll(['Entertainment', 'Food & Dining', 'Shopping']));
    expect(ranked.last, 'Fuel');
  });

  test('generic words like "received" do not count as a mention', () {
    final ranked = rankCategoriesForQuestion(
      'You received 150,000 from Emeka. Was that salary, a gift, or a repayment?',
      [
        _c('Business Income'),
        _c('Loan Received'),
        _c('Gift Received'),
        _c('Salary')
      ],
    ).map((c) => c.name).toList();
    expect(ranked.take(2), containsAll(['Gift Received', 'Salary']));
  });
}
