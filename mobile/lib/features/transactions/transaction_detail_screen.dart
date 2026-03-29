import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/transaction_model.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text(
                'Could not load transaction',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref
                    .read(transactionsProvider.notifier)
                    .fetchTransactions(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (paginated) {
        final transaction =
            paginated.data.where((t) => t.id == transactionId).firstOrNull;
        if (transaction == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Transaction not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          );
        }
        return _TransactionDetailView(transaction: transaction);
      },
    );
  }
}

class _TransactionDetailView extends ConsumerWidget {
  const _TransactionDetailView({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isExpense = transaction.type == 'EXPENSE';
    final amountColor = isExpense ? AppColors.expense : AppColors.accent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.expense),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 16),

          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: amountColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    transaction.type,
                    style: textTheme.labelLarge?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormatter.format(transaction.amount, currency: transaction.currency)}',
                  style: textTheme.displayMedium?.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.currency,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (transaction.convertedAmount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ ${CurrencyFormatter.format(transaction.convertedAmount!, currency: 'USD')}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          _DetailCard(
            children: [
              _DetailRow(
                icon: Icons.store_outlined,
                label: 'Merchant / Description',
                value: transaction.merchantName ??
                    transaction.description ??
                    transaction.counterparty ??
                    'N/A',
              ),
              if (transaction.category != null) ...[
                const _Divider(),
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        transaction.category!.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transaction.category!.name,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (transaction.account != null) ...[
                const _Divider(),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Account',
                  value: transaction.account!.name,
                ),
              ],
              const _Divider(),
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date & Time',
                value: DateFormatter.dateTime(transaction.occurredAt),
              ),
              const _Divider(),
              _DetailRow(
                icon: Icons.source_outlined,
                label: 'Source',
                value: _formatSource(transaction.sourceType),
              ),
              if (transaction.note != null &&
                  transaction.note!.isNotEmpty) ...[
                const _Divider(),
                _DetailRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: transaction.note!,
                ),
              ],
            ],
          ),

          if (transaction.parseConfidence < 1.0 ||
              transaction.categoryConfidence < 1.0) ...[
            const SizedBox(height: 16),
            _ConfidenceCard(transaction: transaction),
          ],

          if (transaction.fxRateUsed != null) ...[
            const SizedBox(height: 16),
            _DetailCard(
              children: [
                _DetailRow(
                  icon: Icons.currency_exchange,
                  label: 'FX Rate Used',
                  value: transaction.fxRateUsed!.toStringAsFixed(4),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatSource(String source) {
    switch (source) {
      case 'SMS':
        return '📱 SMS';
      case 'EMAIL':
        return '📧 Email';
      case 'VOICE':
        return '🎤 Voice';
      case 'MANUAL':
        return '✏️ Manual';
      case 'AI_IMPORT':
        return '🤖 AI Import';
      default:
        return source;
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Transaction',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to delete this transaction? This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(transactionsProvider.notifier)
            .deleteTransaction(transaction.id);
        if (context.mounted) context.pop();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: AppColors.expense,
            ),
          );
        }
      }
    }
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(
                      value ?? '',
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.divider,
      height: 1,
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final parseScore = (transaction.parseConfidence * 100).round();
    final categoryScore = (transaction.categoryConfidence * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confidence Scores',
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ScoreRow(label: 'Parse Confidence', score: parseScore),
          const SizedBox(height: 8),
          _ScoreRow(label: 'Category Confidence', score: categoryScore),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.score});

  final String label;
  final int score;

  Color get _color {
    if (score >= 80) return AppColors.accent;
    if (score >= 50) return AppColors.warning;
    return AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '$score%',
          style: textTheme.bodyMedium?.copyWith(
            color: _color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),
      ],
    );
  }
}
