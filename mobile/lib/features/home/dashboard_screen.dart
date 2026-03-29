import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/providers/auth_provider.dart';
import 'package:bookie_ai/data/providers/dashboard_provider.dart';
import 'package:bookie_ai/data/models/insight_model.dart';
import 'package:bookie_ai/widgets/shimmer_loading.dart';
import 'package:bookie_ai/features/home/widgets/balance_card.dart';
import 'package:bookie_ai/features/home/widgets/quick_actions.dart';
import 'package:bookie_ai/features/home/widgets/transaction_tile.dart';
import 'package:bookie_ai/features/home/widgets/budget_progress_card.dart';
import 'package:bookie_ai/features/home/widgets/goal_progress_card.dart';
import 'package:bookie_ai/features/home/widgets/clarification_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final user = authState.user;
    final currency = user?.primaryCurrency ?? 'USD';

    return Scaffold(
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const SingleChildScrollView(
            child: DashboardShimmer(),
          ),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) => RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(dashboardProvider),
            child: _DashboardContent(
              userName: user?.fullName.split(' ').first ?? 'there',
              currency: currency,
              data: data,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.userName,
    required this.currency,
    required this.data,
  });

  final String userName;
  final String currency;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 12),
        // App bar
        _AppBarRow(userName: userName),
        const SizedBox(height: 20),

        // Clarification banner
        if (data.pendingClarifications > 0) ...[
          ClarificationBanner(
            count: data.pendingClarifications,
            onTap: () => context.push('/transactions'),
          ),
          const SizedBox(height: 16),
        ],

        // Balance card
        BalanceCard(
          totalBalance: data.totalIncome - data.totalExpenses,
          income: data.totalIncome,
          expenses: data.totalExpenses,
          currency: currency,
        ),
        const SizedBox(height: 24),

        // Quick actions
        QuickActions(
          onVoiceLog: () => context.go('/assistant'),
          onAddManual: () => context.push('/transactions'),
          onPayGoal: () => context.push('/goals'),
          onViewInsights: () {},
        ),
        const SizedBox(height: 28),

        // Recent Transactions
        if (data.recentTransactions.isNotEmpty) ...[
          _SectionHeader(
            title: 'Recent Transactions',
            onSeeAll: () => context.push('/transactions'),
          ),
          const SizedBox(height: 4),
          ...data.recentTransactions.take(5).map(
                (tx) => TransactionTile(transaction: tx),
              ),
          const SizedBox(height: 20),
        ],

        // Budget Overview
        if (data.budgetProgress.isNotEmpty) ...[
          _SectionHeader(
            title: 'Budget Overview',
            onSeeAll: () => context.go('/budgets'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.budgetProgress.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return BudgetProgressCard(
                  budget: data.budgetProgress[index],
                  currency: currency,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Goals
        if (data.goalProgress.isNotEmpty) ...[
          _SectionHeader(
            title: 'Goals',
            onSeeAll: () => context.push('/goals'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.goalProgress.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return GoalProgressCard(
                  goal: data.goalProgress[index],
                  currency: currency,
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}

class _AppBarRow extends StatelessWidget {
  const _AppBarRow({required this.userName});

  final String userName;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting,',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                userName,
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const _NotificationBell(),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 26,
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.expense,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.onSeeAll,
  });

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

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
