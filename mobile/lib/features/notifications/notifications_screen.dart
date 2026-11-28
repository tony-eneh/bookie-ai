import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/utils/date_formatter.dart';
import 'package:bookie_ai/data/models/notification_model.dart';
import 'package:bookie_ai/data/providers/notifications_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _icons = <String, IconData>{
    'weekly_summary': Icons.insights,
    'monthly_summary': Icons.insights,
    'goal_risk': Icons.flag_outlined,
    'budget_warning': Icons.pie_chart_outline,
    'clarification': Icons.help_outline,
    'clarification_needed': Icons.help_outline,
    'transaction_detected': Icons.receipt_long_outlined,
    'balance_mismatch': Icons.balance,
  };

  /// Where tapping a notification of each type should go.
  static String? _routeFor(AppNotification n) => switch (n.type) {
        'weekly_summary' || 'monthly_summary' => '/insights',
        'goal_risk' => '/goals',
        'budget_warning' => '/budgets',
        'clarification' || 'clarification_needed' => '/clarifications',
        'transaction_detected' => '/transactions',
        'balance_mismatch' => '/accounts',
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final hasUnread = async.valueOrNull?.any((n) => !n.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(friendlyError(e),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
        ),
        data: (items) => items.isEmpty
            ? const Center(
                child: Text(
                  "Nothing yet. Bookie will let you know when something\nneeds your attention.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationsProvider.notifier).fetch(),
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentSubtle,
                        child: Icon(_icons[n.type] ?? Icons.notifications,
                            color: AppColors.accent),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight:
                              n.isRead ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${n.body}\n${DateFormatter.relative(n.createdAt)}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: n.isRead
                          ? null
                          : const Icon(Icons.circle,
                              size: 10, color: AppColors.accent),
                      onTap: () {
                        if (!n.isRead) {
                          ref
                              .read(notificationsProvider.notifier)
                              .markRead(n.id);
                        }
                        final route = _routeFor(n);
                        if (route != null) context.push(route);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}
