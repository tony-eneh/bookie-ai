import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/category_model.dart';
import 'package:bookie_ai/data/models/clarification_model.dart';
import 'package:bookie_ai/data/providers/categories_provider.dart';
import 'package:bookie_ai/data/providers/clarifications_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';

/// "Bookie asks, you answer": one card per transaction Bookie wasn't sure
/// about. Tapping a category answers it; typing a note answers it too.
class ClarificationsScreen extends ConsumerWidget {
  const ClarificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clarificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Needs your answer')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          icon: Icons.cloud_off,
          text: friendlyError(e),
          action: TextButton(
            onPressed: () => ref.read(clarificationsProvider.notifier).fetch(),
            child: const Text('Try again'),
          ),
        ),
        data: (items) => items.isEmpty
            ? const _Message(
                icon: Icons.check_circle_outline,
                text: "All caught up. Bookie has no questions for you.",
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(clarificationsProvider.notifier).fetch(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ClarificationCard(item: items[i]),
                ),
              ),
      ),
    );
  }
}

class _ClarificationCard extends ConsumerStatefulWidget {
  const _ClarificationCard({required this.item});

  final Clarification item;

  @override
  ConsumerState<_ClarificationCard> createState() => _ClarificationCardState();
}

class _ClarificationCardState extends ConsumerState<_ClarificationCard> {
  final _noteController = TextEditingController();
  bool _busy = false;
  bool _showAllCategories = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.expense,
          ),
        );
        setState(() => _busy = false);
      }
    }
  }

  void _answerWithCategory(Category category) {
    _run(() => ref.read(clarificationsProvider.notifier).respond(
          widget.item.id,
          answerText: category.name,
          categoryId: category.id,
        ));
  }

  void _answerWithNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    _run(() => ref.read(clarificationsProvider.notifier).respond(
          widget.item.id,
          answerText: text,
          source: 'TEXT',
        ));
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.item.transaction;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final options = rankCategoriesForQuestion(
      widget.item.question,
      categories.where((c) => tx == null || c.type == tx.type).toList(),
    );
    final visible = _showAllCategories ? options : options.take(6).toList();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _busy ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.description ?? tx.merchantName ?? 'Transaction',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    '${tx.type == 'EXPENSE' ? '-' : '+'}'
                    '${CurrencyFormatter.format(tx.amount, currency: tx.currency)}',
                    style: TextStyle(
                      color: tx.type == 'EXPENSE'
                          ? AppColors.expense
                          : AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (tx != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  DateFormatter.relative(tx.occurredAt),
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              widget.item.question,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in visible)
                  ActionChip(
                    avatar: Text(c.icon),
                    label: Text(c.name),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.25),
                    ),
                    onPressed: _busy ? null : () => _answerWithCategory(c),
                  ),
                if (!_showAllCategories && options.length > visible.length)
                  ActionChip(
                    label: Text('More (${options.length - visible.length})'),
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    onPressed: () => setState(() => _showAllCategories = true),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    enabled: !_busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _answerWithNote(),
                    decoration: const InputDecoration(
                      hintText: 'Or tell Bookie in your own words',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy ? null : _answerWithNote,
                  icon: const Icon(Icons.send, color: AppColors.accent),
                  tooltip: 'Send answer',
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => ref
                        .read(clarificationsProvider.notifier)
                        .dismiss(widget.item.id)),
                child: const Text(
                  'Skip this one',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// Puts the categories the question mentions first (e.g. "shopping, food or
/// entertainment?"), keeping the rest in their original order.
@visibleForTesting
List<Category> rankCategoriesForQuestion(
  String question,
  List<Category> categories,
) {
  // Words shared by many category names say nothing about which one fits.
  const generic = {
    'received',
    'income',
    'expense',
    'transfer',
    'miscellaneous'
  };
  final q = question.toLowerCase();
  bool mentioned(Category c) => c.name
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((w) => w.length >= 4 && !generic.contains(w))
      // Match on the stem so "gift" finds "gifts".
      .any((w) => RegExp(r'\b' + w.substring(0, w.length - 1)).hasMatch(q));
  return [
    ...categories.where(mentioned),
    ...categories.where((c) => !mentioned(c)),
  ];
}
