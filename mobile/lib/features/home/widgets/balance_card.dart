import 'package:flutter/material.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.income,
    required this.expenses,
    required this.currency,
    this.netCashFlow,
  });

  final double totalBalance;
  final double income;
  final double expenses;
  final String currency;
  final double? netCashFlow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final net = netCashFlow ?? (income - expenses);
    final isPositiveNet = net >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceLight,
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Balance',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalBalance, currency: currency),
            style: textTheme.displayMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositiveNet ? Icons.trending_up : Icons.trending_down,
                color: isPositiveNet ? AppColors.accent : AppColors.expense,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositiveNet ? '+' : ''}${CurrencyFormatter.format(net, currency: currency)}',
                style: textTheme.bodySmall?.copyWith(
                  color: isPositiveNet ? AppColors.accent : AppColors.expense,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' this period',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricColumn(
                  label: 'Income',
                  amount: income,
                  currency: currency,
                  color: AppColors.accent,
                  icon: Icons.arrow_upward,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Expanded(
                child: _MetricColumn(
                  label: 'Expenses',
                  amount: expenses,
                  currency: currency,
                  color: AppColors.expense,
                  icon: Icons.arrow_downward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.icon,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              CurrencyFormatter.format(amount, currency: currency, compact: true),
              style: textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
