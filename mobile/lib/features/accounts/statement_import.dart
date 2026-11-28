import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/constants/api_constants.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/models/account_model.dart';
import 'package:bookie_ai/data/providers/accounts_provider.dart';
import 'package:bookie_ai/data/providers/dashboard_provider.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';

/// Picks a bank statement CSV and imports it into [account]. Rows already
/// recorded are skipped, and the balance is left as it is.
Future<void> importStatementCsv(
  BuildContext context,
  WidgetRef ref,
  Account account,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'txt'],
    withData: true,
  );
  final file = picked?.files.singleOrNull;
  if (file?.bytes == null) return;
  if (file!.size > 2 * 1024 * 1024) {
    messenger.showSnackBar(const SnackBar(
      content: Text('That file is too big. Export one month at a time.'),
      backgroundColor: AppColors.expense,
    ));
    return;
  }

  messenger.showSnackBar(
    SnackBar(content: Text('Importing ${file.name}...')),
  );
  try {
    final response = await ref.read(apiServiceProvider).post(
      ApiConstants.importStatementCsv,
      data: {
        'accountId': account.id,
        'csv': utf8.decode(file.bytes!, allowMalformed: true),
        'fileName': file.name,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final imported = data['transactionsImported'] as int? ?? 0;
    final skipped = data['duplicatesSkipped'] as int? ?? 0;
    ref.invalidate(accountTransactionsProvider(account.id));
    ref.invalidate(dashboardProvider);
    ref.read(transactionsProvider.notifier).fetchTransactions();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(
        'Imported $imported transaction${imported == 1 ? '' : 's'}'
        '${skipped > 0 ? ', skipped $skipped already recorded' : ''}. '
        'Your balance was not changed; reconcile if it looks off.',
      ),
      duration: const Duration(seconds: 6),
    ));
  } catch (e) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('Import failed: ${friendlyError(e)}'),
      backgroundColor: AppColors.expense,
    ));
  }
}
