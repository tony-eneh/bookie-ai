import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/account_model.dart';
import 'package:bookie_ai/data/providers/accounts_provider.dart';
import 'package:bookie_ai/widgets/shimmer_loading.dart';
import 'package:bookie_ai/features/accounts/widgets/create_account_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      body: SafeArea(
        child: accountsAsync.when(
          loading: () => const SingleChildScrollView(
            child: _AccountsShimmer(),
          ),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () =>
                ref.read(accountsProvider.notifier).fetchAccounts(),
          ),
          data: (accounts) => RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () =>
                ref.read(accountsProvider.notifier).fetchAccounts(),
            child: accounts.isEmpty
                ? _EmptyState(onAdd: () => _showCreateSheet(context))
                : _AccountsContent(accounts: accounts),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateSheet(context),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateAccountSheet(),
    );
  }
}

class _AccountsContent extends StatelessWidget {
  const _AccountsContent({required this.accounts});

  final List<Account> accounts;

  double get _totalBalance {
    return accounts.fold(0.0, (sum, a) => sum + (a.convertedBalance ?? a.currentBalance));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 12),
        Text(
          'Accounts',
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),

        _TotalBalanceCard(totalBalance: _totalBalance),
        const SizedBox(height: 20),

        ...accounts.map((account) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AccountCard(account: account),
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({required this.totalBalance});

  final double totalBalance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalBalance, currency: 'USD'),
            style: textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final Account account;

  static const _typeEmojis = {
    'BANK': '🏦',
    'WALLET': '👛',
    'CASH': '💵',
    'SAVINGS': '🏦',
    'BUSINESS': '💼',
  };

  String get _confidenceLabel {
    switch (account.confidence) {
      case 'HIGH':
        return '✅ HIGH';
      case 'MEDIUM':
        return '⚠️ MEDIUM';
      case 'LOW':
        return '❌ LOW';
      default:
        return '';
    }
  }

  Color get _confidenceColor {
    switch (account.confidence) {
      case 'HIGH':
        return AppColors.accent;
      case 'MEDIUM':
        return AppColors.warning;
      case 'LOW':
        return AppColors.expense;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final emoji = _typeEmojis[account.type] ?? '💰';
    final showConverted = account.convertedBalance != null &&
        account.convertedBalance != account.currentBalance;

    return GestureDetector(
      onTap: () => context.push('/accounts/${account.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              account.type,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (account.isPrimary) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PRIMARY',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        account.currentBalance,
                        currency: account.currency,
                      ),
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showConverted) ...[
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(
                          account.convertedBalance!,
                          currency: 'USD',
                          compact: true,
                        ),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (account.confidence != null ||
                account.lastReconciledAt != null) ...[
              const SizedBox(height: 12),
              Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (account.confidence != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _confidenceColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _confidenceLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: _confidenceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (account.lastReconciledAt != null)
                    Text(
                      'Reconciled ${DateFormatter.relative(account.lastReconciledAt!)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Accounts',
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'No accounts yet',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first account to start tracking',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountsShimmer extends StatelessWidget {
  const _AccountsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const ShimmerBox(width: 120, height: 28),
          const SizedBox(height: 20),
          const ShimmerCard(height: 100),
          const SizedBox(height: 20),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerCard(height: 120),
            ),
          ),
        ],
      ),
    );
  }
}
