import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';
import 'package:bookie_ai/data/providers/accounts_provider.dart';
import 'package:bookie_ai/data/providers/auth_provider.dart';
import 'package:bookie_ai/data/providers/dashboard_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';

typedef _Option = ({String value, String label, String? description});

const List<_Option> _personalityOptions = [
  (value: 'GENTLE', label: 'Gentle', description: 'Friendly nudges, no pressure'),
  (value: 'DIRECT', label: 'Direct', description: 'Straight facts, short answers'),
  (value: 'COACH_LIKE', label: 'Coach', description: 'Pushes you toward your goals'),
];

const List<_Option> _notificationOptions = [
  (value: 'MINIMAL', label: 'Minimal', description: 'Only what needs your answer'),
  (value: 'STANDARD', label: 'Standard', description: 'Questions plus budget warnings'),
  (value: 'PROACTIVE', label: 'Proactive', description: 'Also tips and weekly summaries'),
  (value: 'COACH', label: 'Coach', description: 'Regular check-ins on your goals'),
];

const List<_Option> _incomeOptions = [
  (value: 'FIXED_SALARY', label: 'Fixed salary', description: null),
  (value: 'IRREGULAR', label: 'Irregular', description: 'Freelance or variable pay'),
  (value: 'BUSINESS', label: 'Business', description: 'Income from your own business'),
  (value: 'MIXED', label: 'Mixed', description: 'A bit of everything'),
];

const List<_Option> _fxOptions = [
  (value: 'REAL_TIME', label: 'Real-time', description: 'Latest exchange rates'),
  (value: 'DAILY_AVERAGE', label: 'Daily average', description: 'Smoother, once a day'),
  (value: 'MANUAL_OVERRIDE', label: 'Manual', description: 'Use rates you set'),
];

String _labelFor(List<_Option> options, String? value) =>
    options.where((o) => o.value == value).firstOrNull?.label ??
    value ??
    'Not set';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildProfileSection(context, user?.fullName, user?.email),
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Preferences'),
          _buildTile(
            context,
            icon: Icons.attach_money,
            title: 'Primary Currency',
            subtitle: user?.primaryCurrency ?? 'Not set',
            onTap: () => _pick(
              context,
              ref,
              title: 'Primary currency',
              options: [
                for (final c in AppConstants.supportedCurrencies)
                  (
                    value: c,
                    label:
                        '${AppConstants.currencySymbols[c] ?? ''}  $c'.trim(),
                    description: null,
                  ),
              ],
              current: user?.primaryCurrency,
              save: (v) async {
                await ref
                    .read(authProvider.notifier)
                    .updateProfile({'primaryCurrency': v});
                // Totals are converted into this currency: reload them.
                ref.invalidate(dashboardProvider);
                await ref.read(accountsProvider.notifier).fetchAccounts();
              },
            ),
          ),
          _buildTile(
            context,
            icon: Icons.psychology,
            title: 'Assistant Personality',
            subtitle: _labelFor(_personalityOptions, user?.financialPersonality),
            onTap: () => _pickPreference(context, ref, 'financialPersonality',
                'Assistant personality', _personalityOptions,
                user?.financialPersonality),
          ),
          _buildTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notification Mode',
            subtitle: _labelFor(_notificationOptions, user?.notificationMode),
            onTap: () => _pickPreference(context, ref, 'notificationMode',
                'Notification mode', _notificationOptions,
                user?.notificationMode),
          ),
          _buildTile(
            context,
            icon: Icons.work_outline,
            title: 'Income Style',
            subtitle: _labelFor(_incomeOptions, user?.incomeStyle),
            onTap: () => _pickPreference(context, ref, 'incomeStyle',
                'Income style', _incomeOptions, user?.incomeStyle),
          ),
          _buildTile(
            context,
            icon: Icons.currency_exchange,
            title: 'Exchange Rates',
            subtitle: _labelFor(_fxOptions, user?.fxPreference),
            onTap: () => _pickPreference(context, ref, 'fxPreference',
                'Exchange rates', _fxOptions, user?.fxPreference),
          ),
          const SizedBox(height: 8),
          _buildSectionHeader(context, 'Account'),
          _buildTile(
            context,
            icon: Icons.logout,
            title: 'Log Out',
            titleColor: AppColors.expense,
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'BookieAI v${AppConstants.appVersion}',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, String? name, String? email) {
    final initials = (name ?? 'U')
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'User',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email != null)
                  Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.textPrimary,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          : null,
      trailing: const Icon(Icons.chevron_right,
          color: AppColors.textSecondary, size: 20),
      onTap: onTap,
    );
  }

  void _pickPreference(
    BuildContext context,
    WidgetRef ref,
    String field,
    String title,
    List<_Option> options,
    String? current,
  ) {
    _pick(
      context,
      ref,
      title: title,
      options: options,
      current: current,
      save: (v) =>
          ref.read(authProvider.notifier).updatePreferences({field: v}),
    );
  }

  /// Shows [options] in a bottom sheet and saves the chosen value.
  void _pick(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<_Option> options,
    required String? current,
    required Future<void> Function(String value) save,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final o in options)
              ListTile(
                title: Text(o.label,
                    style: const TextStyle(color: AppColors.textPrimary)),
                subtitle: o.description == null
                    ? null
                    : Text(o.description!,
                        style:
                            const TextStyle(color: AppColors.textSecondary)),
                trailing: o.value == current
                    ? const Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (o.value == current) return;
                  try {
                    await save(o.value);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Could not save: ${friendlyError(e)}'),
                        backgroundColor: AppColors.expense,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Log Out',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}
