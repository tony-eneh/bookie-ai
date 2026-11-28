import 'package:bookie_ai/features/assistant/assistant_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads answer and suggestions from the server envelope', () {
    // Shape returned by POST /api/assistant/chat.
    final reply = parseAssistantReply({
      'data': {
        'answer': 'You spent 12,000 on food this week.',
        'suggestions': ['Set a food budget', 'Show last month'],
      },
    });
    expect(reply.answer, 'You spent 12,000 on food this week.');
    expect(reply.suggestions, ['Set a food budget', 'Show last month']);
  });

  test('falls back when the answer is missing', () {
    final reply = parseAssistantReply({'data': {}});
    expect(reply.answer, contains("couldn't process"));
    expect(reply.suggestions, isEmpty);
  });

  group('looksLikeTransaction', () {
    test('statements with an amount are logged', () {
      expect(looksLikeTransaction('I spent 4,500 on lunch'), isTrue);
      expect(looksLikeTransaction('paid 20k for fuel today'), isTrue);
      expect(looksLikeTransaction('Received 150000 from Emeka'), isTrue);
    });

    test('questions go to the assistant', () {
      expect(looksLikeTransaction('How much did I spend this week?'), isFalse);
      expect(looksLikeTransaction('what did I spend on food'), isFalse);
      expect(looksLikeTransaction('Am I on track?'), isFalse);
    });
  });

  test('describeLoggedTransaction reads the voice-log reply', () {
    final text = describeLoggedTransaction({
      'data': {
        'duplicate': false,
        'transaction': {
          'amount': '4500',
          'currency': 'NGN',
          'type': 'EXPENSE',
          'category': {'name': 'Food & Dining'},
        },
        'clarification': {'questionText': 'Was that lunch at work?'},
      },
    });
    expect(text, contains('Food & Dining'));
    expect(text, contains('Was that lunch at work?'));
  });
}
