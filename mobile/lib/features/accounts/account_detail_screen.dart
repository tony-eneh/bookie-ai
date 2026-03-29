import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/account_model.dart';
import 'package:bookie_ai/data/providers/accounts_provider.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';
import 'package:bookie_ai/features/home/widgets/transaction_tile.dart';

class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return accountsAsync.when(
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
                'Could not load account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(accountsProvider.notifier).fetchAccounts(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (accounts) {
        final account = accounts.where((a) => a.id == accountId).firstOrNull;
        if (account == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text(
                'Account not found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          );
        }
        return _AccountDetailView(account: account);
      },
    );
  }
}

class _AccountDetailView extends ConsumerWidget {
  const _AccountDetailView({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(accountsProvider.notifier).fetchAccounts();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),
            _BalanceHeader(account: account),
            const SizedBox(height: 20),
            _ConfidenceCard(account: account),
            const SizedBox(height: 20),
            _QuickActions(
              onReconcile: () => _showReconcileSheet(context, ref),
              onViewTransactions: () => context.push('/transactions'),
            ),
            const SizedBox(height: 24),

            if (account.lastReconciledAt != null) ...[
              Text(
                'Reconciliation History',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _ReconciliationInfo(account: account),
              const SizedBox(height: 24),
            ],

            Text(
              'Recent Transactions',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            transactionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child:
                      CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Could not load transactions',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              data: (paginated) {
                final filtered = paginated.data
                    .where((t) => t.accountId == account.id)
                    .toList();
                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined,
                              size: 40, color: AppColors.textTertiary),
                          const SizedBox(height: 8),
                          Text(
                            'No transactions yet',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: filtered
                      .take(10)
                      .map((tx) => TransactionTile(transaction: tx))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showReconcileSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReconcileSheet(account: account),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            'Current Balance',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(
              account.currentBalance,
              currency: account.currency,
            ),
            style: textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            account.currency,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          if (account.convertedBalance != null &&
              account.convertedBalance != account.currentBalance) ...[
            const SizedBox(height: 8),
            Text(
              '≈ ${CurrencyFormatter.format(account.convertedBalance!, currency: 'USD')}',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final confidence = account.confidence ?? 'HIGH';

    final (icon, label, color, description) = switch (confidence) {
      'HIGH' => (
          '✅',
          'High Confidence',
          AppColors.accent,
          'Balance is verified and up to date'
        ),
      'MEDIUM' => (
          '⚠️',
          'Medium Confidence',
          AppColors.warning,
          'Some transactions may not be reflected'
        ),
      'LOW' => (
          '❌',
          'Low Confidence',
          AppColors.expense,
          'Balance may be inaccurate – reconciliation needed'
        ),
      _ => (
          '✅',
          'High Confidence',
          AppColors.accent,
          'Balance is verified and up to date'
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onReconcile,
    required this.onViewTransactions,
  });

  final VoidCallback onReconcile;
  final VoidCallback onViewTransactions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.balance,
            label: 'Reconcile',
            color: AppColors.accent,
            onTap: onReconcile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            color: AppColors.info,
            onTap: onViewTransactions,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReconciliationInfo extends StatelessWidget {
  const _ReconciliationInfo({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'Last Reconciled',
            value: account.lastReconciledAt != null
                ? DateFormatter.dateTime(account.lastReconciledAt!)
                : 'Never',
          ),
          if (account.lastReconciledBalance != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Reconciled Balance',
              value: CurrencyFormatter.format(
                account.lastReconciledBalance!,
                currency: account.currency,
              ),
            ),
          ],
          if (account.lastReconciledBalance != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              label: 'Drift',
              value: CurrencyFormatter.format(
                account.currentBalance - account.lastReconciledBalance!,
                currency: account.currency,
                showSign: true,
              ),
              valueColor: (account.currentBalance -
                          account.lastReconciledBalance!)
                      .abs() >
                  0.01
                  ? AppColors.warning
                  : AppColors.accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReconcileSheet extends ConsumerStatefulWidget {
  const _ReconcileSheet({required this.account});

  final Account account;

  @override
  ConsumerState<_ReconcileSheet> createState() => _ReconcileSheetState();
}

class _ReconcileSheetState extends ConsumerState<_ReconcileSheet> {
  final _balanceController = TextEditingController();
  String _source = 'Manual';
  bool _isLoading = false;

  static const _sources = ['Manual', 'SMS', 'Email', 'Statement'];

  Account get account => widget.account;

  double? get _enteredBalance => double.tryParse(_balanceController.text);

  double? get _drift {
    final entered = _enteredBalance;
    if (entered == null) return null;
    return entered - account.currentBalance;
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final balance = _enteredBalance;
    if (balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid balance'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(accountsProvider.notifier)
          .reconcile(account.id, balance);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconciliation failed: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reconcile Balance',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Estimated Balance',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(
                      account.currentBalance,
                      currency: account.currency,
                    ),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _balanceController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Actual Balance',
                prefixText:
                    '${CurrencyFormatter.symbolFor(account.currency)} ',
                prefixStyle:
                    const TextStyle(color: AppColors.textSecondary),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) => setState(() {}),
            ),

            if (_drift != null && _drift!.abs() > 0.001) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drift: ${CurrencyFormatter.format(_drift!, currency: account.currency, showSign: true)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            Text(
              'Source',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _sources.map((s) {
                final selected = _source == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  onSelected: (_) => setState(() => _source = s),
                  selectedColor: AppColors.accent.withValues(alpha: 0.2),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.accent
                        : AppColors.surfaceBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Reconcile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
