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
}
