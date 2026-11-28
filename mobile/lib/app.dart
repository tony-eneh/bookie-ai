import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/core/theme/app_theme.dart';
import 'package:bookie_ai/core/router/app_router.dart';
import 'package:bookie_ai/data/providers/auth_provider.dart';
import 'package:bookie_ai/data/providers/dashboard_provider.dart';
import 'package:bookie_ai/data/providers/transactions_provider.dart';
import 'package:bookie_ai/data/services/sms_import_service.dart';

class BookieApp extends ConsumerStatefulWidget {
  const BookieApp({super.key});

  @override
  ConsumerState<BookieApp> createState() => _BookieAppState();
}

class _BookieAppState extends ConsumerState<BookieApp>
    with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scanSms();
  }

  /// Picks up bank alerts that arrived since the last look (if the user
  /// turned SMS reading on) whenever the app is opened or brought back.
  Future<void> _scanSms() async {
    final sms = ref.read(smsImportServiceProvider);
    if (_scanning ||
        !ref.read(authProvider).isAuthenticated ||
        !await sms.isEnabled()) {
      return;
    }
    _scanning = true;
    try {
      final result = await sms.scan();
      if (result.recorded > 0) {
        ref.invalidate(dashboardProvider);
        ref.read(transactionsProvider.notifier).fetchTransactions();
        _messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(
            'Bookie picked up ${result.recorded} new '
            'transaction${result.recorded == 1 ? '' : 's'} from your bank SMS.',
          ),
        ));
      }
    } catch (_) {
      // Best effort: try again next time the app opens.
    } finally {
      _scanning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    ref.listen(authProvider, (prev, next) {
      if (next.isAuthenticated && prev?.isAuthenticated != true) _scanSms();
    });

    return MaterialApp.router(
      title: 'BookieAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
    );
  }
}
