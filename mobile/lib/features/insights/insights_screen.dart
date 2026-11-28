import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/json_parsers.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:bookie_ai/features/insights/income_target_card.dart';

/// GET /insights/monthly, already converted to the user's currency.
class MonthlyReport {
  MonthlyReport.fromJson(Map<String, dynamic> j)
      : currency = j['currency'] as String? ?? 'USD',
        income = parseDouble(j['income']),
        expenses = parseDouble(j['expenses']),
        net = parseDouble(j['net']),
        savingsRate = parseDouble(j['savingsRate']),
        categories = [
          for (final c in (j['categories'] as List? ?? const []))
            (
              name: (c as Map)['name'] as String,
              icon: c['icon'] as String? ?? '📦',
              total: parseDouble(c['total']),
              percentage: parseDouble(c['percentage']),
            ),
        ],
        expenseChangePercent =
            parseDouble((j['trends'] as Map?)?['expenseChangePercent']),
        incomeChangePercent =
            parseDouble((j['trends'] as Map?)?['incomeChangePercent']),
        summary = (j['aiSummary'] as Map?)?['body'] as String?,
        recommendations = [
          for (final r
              in ((j['aiSummary'] as Map?)?['recommendations'] as List? ??
                  const []))
            r.toString(),
        ];

  final String currency;
  final double income, expenses, net, savingsRate;
  final double expenseChangePercent, incomeChangePercent;
  final List<({String name, String icon, double total, double percentage})>
      categories;
  final String? summary;
  final List<String> recommendations;
}

final monthlyReportProvider = FutureProvider.autoDispose
    .family<MonthlyReport, DateTime>((ref, month) async {
  final response = await ref.read(apiServiceProvider).get(
    ApiConstants.monthlyInsights,
    queryParameters: {'month': '${month.month}', 'year': '${month.year}'},
  );
  return MonthlyReport.fromJson(response.data['data'] as Map<String, dynamic>);
});

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shift(int months) => setState(
        () => _month = DateTime(_month.year, _month.month + months),
      );

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(monthlyReportProvider(_month));
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                DateFormat('MMMM y').format(_month),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: _isCurrentMonth ? null : () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(friendlyError(e),
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (r) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(monthlyReportProvider(_month)),
                child: _ReportView(report: r, showTarget: _isCurrentMonth),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView({required this.report, this.showTarget = false});

  final MonthlyReport report;
  final bool showTarget;

  String _money(double v, {bool sign = false}) =>
      CurrencyFormatter.format(v, currency: report.currency, showSign: sign);

  @override
  Widget build(BuildContext context) {
    final r = report;
    final spendingUp = r.expenseChangePercent > 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        if (showTarget) ...[
          const IncomeTargetCard(),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _Stat(
                  label: 'Income',
                  value: _money(r.income),
                  color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                  label: 'Spent',
                  value: _money(r.expenses),
                  color: AppColors.expense),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Net',
                value: _money(r.net, sign: true),
                color: r.net >= 0 ? AppColors.accent : AppColors.expense,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Saved',
                value: '${r.savingsRate.toStringAsFixed(0)}%',
                color: AppColors.info,
              ),
            ),
          ],
        ),
        if (r.expenseChangePercent != 0) ...[
          const SizedBox(height: 12),
          Text(
            'Spending is ${spendingUp ? 'up' : 'down'} '
            '${r.expenseChangePercent.abs().toStringAsFixed(0)}% on last month.',
            style: TextStyle(
              color: spendingUp ? AppColors.warning : AppColors.accent,
            ),
          ),
        ],
        const SizedBox(height: 28),
        const _Heading('Where your money went'),
        const SizedBox(height: 12),
        if (r.categories.isEmpty)
          const Text('No spending recorded this month.',
              style: TextStyle(color: AppColors.textSecondary))
        else
          for (final c in r.categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('${c.icon}  ', style: const TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(c.name,
                            style:
                                const TextStyle(color: AppColors.textPrimary)),
                      ),
                      Text(_money(c.total),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (c.percentage / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceLight,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
        if (r.summary != null || r.recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _Heading('Bookie\'s take'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (r.summary != null)
                  Text(r.summary!,
                      style: const TextStyle(
                          color: AppColors.textPrimary, height: 1.45)),
                for (final rec in r.recommendations)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(rec,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
