import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/currency_formatter.dart';
import 'package:bookie_ai/core/utils/json_parsers.dart';
import 'package:bookie_ai/data/services/api_service.dart';

/// GET /income-targets/current (null when no target is set).
class IncomeTargetProgress {
  IncomeTargetProgress.fromJson(Map<String, dynamic> j)
      : id = (j['target'] as Map)['id'] as String,
        title = (j['target'] as Map)['title'] as String,
        target = parseDouble((j['target'] as Map)['targetMonthlyIncome']),
        currency = j['currency'] as String,
        earned = parseDouble(j['earnedThisMonth']),
        remaining = parseDouble(j['remaining']),
        percentage = parseDouble(j['percentage']),
        neededPerDay = parseDouble(j['neededPerDay']),
        onTrack = j['onTrack'] as bool? ?? false;

  final String id, title, currency;
  final double target, earned, remaining, percentage, neededPerDay;
  final bool onTrack;
}

final incomeTargetProvider =
    FutureProvider.autoDispose<IncomeTargetProgress?>((ref) async {
  final response =
      await ref.read(apiServiceProvider).get(ApiConstants.currentIncomeTarget);
  final data = response.data['data'];
  return data is Map<String, dynamic>
      ? IncomeTargetProgress.fromJson(data)
      : null;
});

/// This month's income against the user's target, with set / change.
class IncomeTargetCard extends ConsumerWidget {
  const IncomeTargetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incomeTargetProvider);
    return async.maybeWhen(
      data: (p) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: p == null
            ? Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Set a monthly income target and Bookie will track '
                      'your progress.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _editTarget(context, ref, null),
                    child: const Text('Set target'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Income target',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _editTarget(context, ref, p),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                  Text(
                    '${CurrencyFormatter.format(p.earned, currency: p.currency)}'
                    ' of ${CurrencyFormatter.format(p.target, currency: p.currency)}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (p.percentage / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceLight,
                      color: p.onTrack ? AppColors.accent : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.remaining <= 0
                        ? 'Target reached this month.'
                        : '${CurrencyFormatter.format(p.remaining, currency: p.currency)} to go, '
                            'about ${CurrencyFormatter.format(p.neededPerDay, currency: p.currency, compact: true)} a day.',
                    style: TextStyle(
                      color: p.onTrack ? AppColors.accent : AppColors.warning,
                    ),
                  ),
                ],
              ),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _editTarget(
    BuildContext context,
    WidgetRef ref,
    IncomeTargetProgress? current,
  ) async {
    final controller = TextEditingController(
      text: current == null ? '' : current.target.toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Monthly income target'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          decoration: const InputDecoration(labelText: 'Amount per month'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value <= 0) return;
    final api = ref.read(apiServiceProvider);
    try {
      if (current == null) {
        await api.post(ApiConstants.incomeTargets,
            data: {'title': 'Monthly income', 'targetMonthlyIncome': value});
      } else {
        await api.patch(ApiConstants.incomeTarget(current.id),
            data: {'targetMonthlyIncome': value});
      }
      ref.invalidate(incomeTargetProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: ${friendlyError(e)}'),
          backgroundColor: AppColors.expense,
        ));
      }
    }
  }
}
