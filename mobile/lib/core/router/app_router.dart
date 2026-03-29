import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/features/splash/splash_screen.dart';
import 'package:bookie_ai/features/onboarding/onboarding_screen.dart';
import 'package:bookie_ai/features/auth/login_screen.dart';
import 'package:bookie_ai/features/auth/register_screen.dart';
import 'package:bookie_ai/features/home/dashboard_screen.dart';
import 'package:bookie_ai/features/accounts/accounts_screen.dart';
import 'package:bookie_ai/features/accounts/account_detail_screen.dart';
import 'package:bookie_ai/features/transactions/transactions_screen.dart';
import 'package:bookie_ai/features/transactions/transaction_detail_screen.dart';
import 'package:bookie_ai/features/assistant/assistant_screen.dart';
import 'package:bookie_ai/features/budgets/budgets_screen.dart';
import 'package:bookie_ai/features/goals/goals_screen.dart';
import 'package:bookie_ai/features/goals/goal_detail_screen.dart';
import 'package:bookie_ai/features/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

abstract final class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/accounts',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AccountsScreen(),
            ),
          ),
          GoRoute(
            path: '/assistant',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AssistantScreen(),
            ),
          ),
          GoRoute(
            path: '/budgets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BudgetsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) => AccountDetailScreen(
          accountId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) => TransactionDetailScreen(
          transactionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (context, state) => GoalDetailScreen(
          goalId: state.pathParameters['id']!,
        ),
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  int _locationToIndex(String location) {
    if (location.startsWith('/accounts')) return 1;
    if (location.startsWith('/assistant')) return 2;
    if (location.startsWith('/budgets')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location =
        GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/accounts');
            case 2:
              context.go('/assistant');
            case 3:
              context.go('/budgets');
            case 4:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}


