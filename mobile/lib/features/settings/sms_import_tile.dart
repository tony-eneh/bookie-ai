import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/theme/app_colors.dart';
import 'package:bookie_ai/data/providers/dashboard_provider.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';
import 'package:bookie_ai/data/services/api_service.dart';
import 'package:bookie_ai/data/services/sms_import_service.dart';

/// Settings switch for reading bank alert SMS (Android only), plus a
/// "scan now" action once it's on.
class SmsImportTile extends ConsumerStatefulWidget {
  const SmsImportTile({super.key});

  @override
  ConsumerState<SmsImportTile> createState() => _SmsImportTileState();
}

class _SmsImportTileState extends ConsumerState<SmsImportTile> {
  bool _busy = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _sms.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _refresh() async {
    final v = await _sms.isEnabled();
    if (mounted) setState(() => _enabled = v);
  }

  SmsImportService get _sms => ref.read(smsImportServiceProvider);

  Future<void> _toggle(bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!on) {
      await _sms.disable();
      await _refresh();
      return;
    }
    final granted = await _sms.enable();
    await _refresh();
    if (!granted) {
      messenger.showSnackBar(const SnackBar(
        content: Text(
          'BookieAI needs SMS access to read bank alerts. You can allow it '
          'in Android settings, or keep adding transactions yourself.',
        ),
      ));
      return;
    }
    await _scanNow(firstTime: true);
  }

  Future<void> _scanNow({bool firstTime = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(SnackBar(
      content: Text(firstTime
          ? 'Reading bank alerts from the last 30 days...'
          : 'Checking for new bank alerts...'),
    ));
    try {
      final r = await _sms.scan();
      ref.invalidate(dashboardProvider);
      ref.read(transactionsProvider.notifier).fetchTransactions();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(r.recorded == 0
            ? 'No new bank transactions found.'
            : 'Added ${r.recorded} transaction${r.recorded == 1 ? '' : 's'} '
                'from your SMS.'),
      ));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text('Could not read SMS: ${friendlyError(e)}'),
        backgroundColor: AppColors.expense,
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_sms.isSupported) return const SizedBox.shrink();
    final enabled = _enabled;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.sms_outlined,
              color: AppColors.textSecondary),
          title: const Text('Read bank SMS',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
          subtitle: const Text(
            'Turn bank alerts into transactions automatically, even when '
            'BookieAI is closed (about every 15 minutes). Only transaction '
            'alerts are sent; OTPs are ignored.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          value: enabled,
          onChanged: _busy ? null : _toggle,
        ),
        if (enabled)
          ListTile(
            leading: const Icon(Icons.refresh, color: AppColors.textSecondary),
            title: const Text('Check bank SMS now',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
            enabled: !_busy,
            onTap: _scanNow,
          ),
      ],
    );
  }
}
