import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/providers/auth_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';

/// Downloads everything BookieAI stores about the user as a JSON file and
/// opens the share sheet so they can save or send it.
Future<void> exportMyData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(content: Text('Preparing your data...')),
  );
  try {
    final response = await ref.read(apiServiceProvider).get(ApiConstants.userExport);
    final json = const JsonEncoder.withIndent('  ').convert(response.data['data']);
    final dir = await getTemporaryDirectory();
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/bookie-ai-export-$date.json');
    await file.writeAsString(json);
    messenger.hideCurrentSnackBar();
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'My BookieAI data',
      ),
    );
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Export failed: ${friendlyError(e)}'),
        backgroundColor: AppColors.expense,
      ),
    );
  }
}

/// Asks for confirmation (typing DELETE, plus the password) and permanently
/// deletes the account and all its data, then signs out.
Future<void> confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const _DeleteAccountDialog(),
  );
  if (confirmed == true) {
    await ref.read(authProvider.notifier).logout();
  }
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _confirm = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _confirm.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiServiceProvider).post(
        ApiConstants.userDelete,
        data: {
          'confirm': _confirm.text.trim(),
          if (_password.text.isNotEmpty) 'password': _password.text,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _confirm.text.trim() == 'DELETE' && !_busy;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text(
        'Delete account?',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your accounts, transactions, budgets, '
              'goals and everything else. It cannot be undone. Export your '
              'data first if you want a copy.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirm,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Type DELETE'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'Leave empty if you only use Google sign-in',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.expense)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: canDelete ? _delete : null,
          child: Text(
            _busy ? 'Deleting...' : 'Delete forever',
            style: TextStyle(
              color: canDelete ? AppColors.expense : AppColors.textDisabled,
            ),
          ),
        ),
      ],
    );
  }
}
