import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/json_parsers.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';

class _Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;

  const _Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
  });
}

/// Parses the `{answer, suggestions}` payload returned by the assistant
/// endpoints (inside the `{data: ...}` envelope).
@visibleForTesting
({String answer, List<String> suggestions}) parseAssistantReply(
  Object? body,
) {
  final payload = body is Map && body['data'] is Map ? body['data'] : body;
  if (payload is! Map) {
    return (answer: _fallbackReply, suggestions: const <String>[]);
  }
  final answer = payload['answer'] ?? payload['response'];
  final suggestions = payload['suggestions'];
  return (
    answer: answer is String && answer.trim().isNotEmpty
        ? answer
        : _fallbackReply,
    suggestions: suggestions is List
        ? suggestions.map((s) => s.toString()).toList()
        : const <String>[],
  );
}

const _fallbackReply = "I'm sorry, I couldn't process that right now.";

/// "I spent 4,500 on lunch", "paid 20k for fuel", "got 150000 from Emeka":
/// statements to record, rather than questions to answer.
@visibleForTesting
bool looksLikeTransaction(String text) {
  final t = text.toLowerCase().trim();
  if (t.endsWith('?') || !RegExp(r'\d').hasMatch(t)) return false;
  return RegExp(
    r'\b(spent|spend|paid|pay|bought|buy|got paid|received|earned|sent|transferred|log)\b',
  ).hasMatch(t);
}

/// Bookie's reply after POST /ingestion/voice-log.
@visibleForTesting
String describeLoggedTransaction(Object? body) {
  final data = body is Map && body['data'] is Map ? body['data'] as Map : body;
  if (data is! Map || data['transaction'] is! Map) return _fallbackReply;
  final tx = data['transaction'] as Map;
  final amount = CurrencyFormatter.format(
    parseDouble(tx['amount']),
    currency: tx['currency'] as String? ?? 'USD',
  );
  if (data['duplicate'] == true) {
    return 'That one is already recorded ($amount).';
  }
  final category = (tx['category'] as Map?)?['name'] as String?;
  final direction = tx['type'] == 'INCOME' ? 'income' : 'expense';
  final logged = category == null
      ? 'Logged $amount as an $direction.'
      : 'Logged $amount under $category.';
  final question = (data['clarification'] as Map?)?['questionText'] as String?;
  return question == null ? logged : '$logged $question';
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  late AnimationController _pulseController;
  final _speech = SpeechToText();
  final _tts = FlutterTts();
  bool _speechReady = false;

  final _suggestions = [
    'How much did I spend this week?',
    "What's my budget status?",
    'Am I on track for my goals?',
    'Log an expense',
    'Simulate a scenario',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _messages.add(_Message(
      text:
          "Hi! Ask me anything about your money, or tell me what you spent "
          "(\"I spent 4,500 on lunch\"). Tap the mic to talk.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Sends a question to the assistant, or records a transaction when the
  /// text is a statement like "I spent 4,500 on lunch". Spoken replies are
  /// read aloud when [spoken] is true.
  Future<void> _sendMessage(String text, {bool spoken = false}) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    final isLog = looksLikeTransaction(text);

    setState(() {
      _messages.add(_Message(
        text: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiServiceProvider);
      final ({String answer, List<String> suggestions}) reply;
      if (isLog) {
        final response = await api.post(
          ApiConstants.voiceLog,
          data: {'text': text.trim()},
        );
        reply = (
          answer: describeLoggedTransaction(response.data),
          suggestions: const ['How much did I spend this week?'],
        );
      } else {
        final response = await api.post(
          ApiConstants.assistantChat,
          data: {'message': text.trim()},
        );
        reply = parseAssistantReply(response.data);
      }

      setState(() {
        _messages.add(_Message(
          text: reply.answer,
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: reply.suggestions,
        ));
      });
      if (spoken) await _tts.speak(reply.answer);
    } catch (e) {
      setState(() {
        _messages.add(_Message(
          text: friendlyError(e),
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setListening(bool value) {
    if (!mounted) return;
    setState(() {
      _isListening = value;
      if (value) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop(); // the final result then sends the message
      _setListening(false);
      return;
    }
    await _tts.stop();
    if (!_speechReady) {
      _speechReady = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _setListening(false);
          }
        },
        onError: (_) => _setListening(false),
      );
    }
    if (!_speechReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Voice input needs microphone access and a speech service. '
            'You can type instead.',
          ),
        ));
      }
      return;
    }
    _setListening(true);
    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        setState(() => _controller.text = result.recognizedWords);
        if (result.finalResult) {
          _setListening(false);
          _sendMessage(result.recognizedWords, spoken: true);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.length <= 1 && !_isLoading
                ? _buildEmptyState()
                : _buildMessageList(),
          ),
          if (_isLoading) _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildBubble(_messages.first),
          const SizedBox(height: 32),
          const Text(
            'Try asking...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map((s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 13)),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                      onPressed: () => s == 'Log an expense'
                          ? setState(() => _controller.text = 'I spent ')
                          : _sendMessage(s),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isLast = index == _messages.length - 1;
        if (!isLast || message.isUser || message.suggestions.isEmpty) {
          return _buildBubble(message);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBubble(message),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.suggestions
                    .map((s) => ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 13)),
                          backgroundColor: AppColors.surface,
                          side: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                          onPressed: _isLoading ? null : () => _sendMessage(s),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(_Message message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? AppColors.accent : AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Thinking...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(
          top: BorderSide(
            color: AppColors.surface,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              return Transform.scale(
                scale: _isListening ? scale : 1.0,
                child: child,
              );
            },
            child: GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isListening ? AppColors.expense : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty || !_isListening) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _sendMessage(_controller.text),
              icon: const Icon(Icons.send, color: AppColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}
