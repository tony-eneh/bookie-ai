import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/providers/goals_provider.dart';
import 'package:bookie_ai/data/models/goal_model.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;
  const GoalDetailScreen({super.key, required this.goalId});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  Goal? _goal;
  GoalProjection? _projection;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    setState(() => _isLoading = true);
    try {
      final goal =
          await ref.read(goalsProvider.notifier).getGoal(widget.goalId);
      final projection =
          await ref.read(goalsProvider.notifier).getProjection(widget.goalId);
      setState(() {
        _goal = goal;
        _projection = projection;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final goal = _goal;
    if (goal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Goal')),
        body: const Center(
          child: Text('Goal not found',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(goal.title)),
      body: RefreshIndicator(
        onRefresh: _loadGoal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildProgressHero(progress, goal),
              const SizedBox(height: 24),
              _buildStatsGrid(goal),
              const SizedBox(height: 24),
              if (_projection != null) _buildCoaching(_projection!),
              const SizedBox(height: 24),
              _buildContributeButton(goal),
              if (goal.contributions != null &&
                  goal.contributions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildContributions(goal),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHero(double progress, Goal goal) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: AppColors.surface,
                color: _statusColor(goal.status),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  goal.status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: _statusColor(goal.status),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Goal goal) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard('Target',
            CurrencyFormatter.format(goal.targetAmount, currency: goal.targetCurrency)),
        _statCard('Saved',
            CurrencyFormatter.format(goal.currentAmount, currency: goal.targetCurrency)),
        if (goal.monthlyRequired != null)
          _statCard(
              'Monthly Needed',
              CurrencyFormatter.format(
                  goal.monthlyRequired!, currency: goal.targetCurrency)),
        if (goal.targetDate != null)
          _statCard('Target Date', DateFormatter.fullDate(goal.targetDate!)),
      ],
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCoaching(GoalProjection p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              const Text('AI Coaching',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.coaching,
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContributeButton(Goal goal) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showContributeSheet(goal),
        icon: const Icon(Icons.add),
        label: const Text('Add Contribution'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showContributeSheet(Goal goal) {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Contribution',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Amount (${goal.targetCurrency})',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.primary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text) ?? 0;
                  if (amount <= 0) return;
                  Navigator.pop(ctx);
                  await ref.read(goalsProvider.notifier).addContribution(
                        goal.id,
                        {
                          'amount': amount,
                          'currency': goal.targetCurrency,
                          'contributionDate': DateTime.now().toIso8601String(),
                        },
                      );
                  _loadGoal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributions(Goal goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contributions',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...goal.contributions!.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormatter.fullDate(c.contributionDate),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    CurrencyFormatter.format(c.amount, currency: c.currency),
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACHIEVED':
        return AppColors.accent;
      case 'ON_TRACK':
        return Colors.green;
      case 'AT_RISK':
        return Colors.amber;
      case 'OFF_TRACK':
        return AppColors.expense;
      default:
        return AppColors.textSecondary;
    }
  }
}
