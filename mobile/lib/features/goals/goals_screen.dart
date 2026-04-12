import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/data/models/goal_model.dart';
import 'package:bookie_ai/data/providers/goals_provider.dart';
import 'package:bookie_ai/widgets/shimmer_loading.dart';
import 'package:bookie_ai/features/goals/widgets/create_goal_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      body: SafeArea(
        child: goalsAsync.when(
          loading: () => const SingleChildScrollView(child: _GoalsShimmer()),
          error: (error, _) => _ErrorView(
            message: error.toString(),
            onRetry: () => ref.read(goalsProvider.notifier).fetchGoals(),
          ),
          data: (goals) => RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(goalsProvider.notifier).fetchGoals(),
            child: goals.isEmpty
                ? _EmptyState(onAdd: () => _showCreateSheet(context))
                : _GoalsContent(goals: goals),
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
      builder: (_) => const CreateGoalSheet(),
    );
  }
}

class _GoalsContent extends StatefulWidget {
  const _GoalsContent({required this.goals});

  final List<Goal> goals;

  @override
  State<_GoalsContent> createState() => _GoalsContentState();
}

class _GoalsContentState extends State<_GoalsContent> {
  bool _showAchieved = false;

  List<Goal> get _filtered => widget.goals
      .where((g) =>
          _showAchieved ? g.status == 'ACHIEVED' : g.status != 'ACHIEVED')
      .toList();

  double get _totalSaved =>
      widget.goals.fold(0.0, (sum, g) => sum + g.currentAmount);

  int get _activeCount =>
      widget.goals.where((g) => g.status != 'ACHIEVED').length;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 12),
        Text(
          'Goals',
          style: textTheme.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        _SummaryRow(activeCount: _activeCount, totalSaved: _totalSaved),
        const SizedBox(height: 16),
        Row(
          children: [
            _TabButton(
              label: 'Active',
              selected: !_showAchieved,
              onTap: () => setState(() => _showAchieved = false),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Achieved',
              selected: _showAchieved,
              onTap: () => setState(() => _showAchieved = true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                _showAchieved ? 'No achieved goals yet' : 'No active goals',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ..._filtered.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(goal: goal),
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.activeCount, required this.totalSaved});

  final int activeCount;
  final double totalSaved;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('$activeCount',
                    style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.accent, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Active Goals',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  CurrencyFormatter.format(totalSaved,
                      currency: 'USD', compact: true),
                  style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text('Total Saved',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final Goal goal;

  Color get _statusColor => switch (goal.status) {
        'ON_TRACK' => AppColors.accent,
        'AT_RISK' => AppColors.warning,
        'OFF_TRACK' => AppColors.expense,
        'ACHIEVED' => AppColors.accent,
        _ => AppColors.textSecondary,
      };

  Color get _priorityColor => switch (goal.priority) {
        'HIGH' => AppColors.expense,
        'MEDIUM' => AppColors.warning,
        _ => AppColors.info,
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = goal.percentComplete;
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => context.push('/goals/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    strokeWidth: 5,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(_statusColor),
                  ),
                  Text(
                    '${percent.toStringAsFixed(0)}%',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _priorityColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          goal.priority,
                          style: textTheme.labelSmall?.copyWith(
                            color: _priorityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${CurrencyFormatter.format(goal.currentAmount, currency: goal.targetCurrency, compact: true)} / ${CurrencyFormatter.format(goal.targetAmount, currency: goal.targetCurrency, compact: true)}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          goal.status.replaceAll('_', ' '),
                          style: textTheme.labelSmall?.copyWith(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (goal.monthlyRequired != null)
                        Text(
                          '${CurrencyFormatter.format(goal.monthlyRequired!, currency: goal.targetCurrency, compact: true)}/mo',
                          style: textTheme.bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        daysLeft > 0 ? '${daysLeft}d left' : 'Past due',
                        style: textTheme.bodySmall?.copyWith(
                          color: daysLeft > 0
                              ? AppColors.textTertiary
                              : AppColors.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          child: Text('Goals',
              style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('No goals yet',
                  style: textTheme.titleLarge
                      ?.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text('Set a financial goal to start saving',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Create Goal'),
                style:
                    FilledButton.styleFrom(backgroundColor: AppColors.accent),
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
            const Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: textTheme.titleLarge
                    ?.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(message,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
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

class _GoalsShimmer extends StatelessWidget {
  const _GoalsShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const ShimmerBox(width: 80, height: 28),
          const SizedBox(height: 20),
          const Row(children: [
            Expanded(child: ShimmerCard(height: 80)),
            SizedBox(width: 12),
            Expanded(child: ShimmerCard(height: 80)),
          ]),
          const SizedBox(height: 20),
          ...List.generate(
              3,
              (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerCard(height: 110),
                  )),
        ],
      ),
    );
  }
}
