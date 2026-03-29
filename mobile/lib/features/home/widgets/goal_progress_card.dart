import 'package:flutter/material.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/data/models/insight_model.dart';

class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    super.key,
    required this.goal,
    required this.currency,
    this.onTap,
  });

  final GoalProgress goal;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = (goal.percentage / 100).clamp(0.0, 1.0);
    final statusColor = _statusColor(goal.status);
    final statusLabel = _statusLabel(goal.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              goal.title,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 5,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                        Text(
                          '${goal.percentage.toStringAsFixed(0)}%',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${CurrencyFormatter.format(goal.currentAmount, currency: currency, compact: true)} / ${CurrencyFormatter.format(goal.targetAmount, currency: currency, compact: true)}',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'ON_TRACK' => AppColors.accent,
      'AT_RISK' => AppColors.warning,
      'OFF_TRACK' => AppColors.expense,
      'ACHIEVED' => AppColors.accent,
      _ => AppColors.textSecondary,
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'ON_TRACK' => 'On Track',
      'AT_RISK' => 'At Risk',
      'OFF_TRACK' => 'Off Track',
      'ACHIEVED' => 'Achieved!',
      _ => status,
    };
  }
}
