import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/core/constants/app_constants.dart';
import 'package:bookie_ai/data/providers/auth_provider.dart';

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
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          _buildTile(
            context,
            icon: Icons.psychology,
            title: 'Financial Personality',
            subtitle: user?.financialPersonality ?? 'Not set',
            onTap: () {},
          ),
          _buildTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notification Mode',
            subtitle: user?.notificationMode ?? 'Standard',
            onTap: () {},
          ),
          _buildTile(
            context,
            icon: Icons.work_outline,
            title: 'Income Style',
            subtitle: user?.incomeStyle ?? 'Not set',
            onTap: () {},
          ),
          _buildTile(
            context,
            icon: Icons.currency_exchange,
            title: 'FX Preference',
            subtitle: user?.fxPreference ?? 'Real-time',
            onTap: () {},
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

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: AppConstants.supportedCurrencies
            .map((c) => ListTile(
                  title: Text(c,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  onTap: () => Navigator.pop(context),
                ))
            .toList(),
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
