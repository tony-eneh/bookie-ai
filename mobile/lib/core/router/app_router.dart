import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookie_ai/features/splash/splash_screen.dart';
import 'package:bookie_ai/features/onboarding/onboarding_screen.dart';
import 'package:bookie_ai/features/auth/login_screen.dart';
import 'package:bookie_ai/features/auth/register_screen.dart';
import 'package:bookie_ai/features/home/dashboard_screen.dart';

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
              child: _PlaceholderScreen(title: 'Accounts'),
            ),
          ),
          GoRoute(
            path: '/assistant',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Assistant'),
            ),
          ),
          GoRoute(
            path: '/budgets',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Budgets'),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _PlaceholderScreen(title: 'Settings'),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts/:id',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Account ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Transactions'),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Transaction ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: '/goals',
        builder: (context, state) => const _PlaceholderScreen(title: 'Goals'),
      ),
      GoRoute(
        path: '/goals/:id',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Goal ${state.pathParameters['id']}',
        ),
      ),
      GoRoute(
        path: '/budgets/:id',
        builder: (context, state) => _PlaceholderScreen(
          title: 'Budget ${state.pathParameters['id']}',
        ),
      ),
    ],
    redirect: (context, state) {
      // TODO: Replace with actual auth/onboarding state checks
      // final isAuthenticated = ref.read(authProvider).isAuthenticated;
      // final isOnboarded = ref.read(onboardingProvider).isComplete;
      // final isAuthRoute = state.matchedLocation == '/login' ||
      //     state.matchedLocation == '/register';
      //
      // if (!isAuthenticated && !isAuthRoute &&
      //     state.matchedLocation != '/splash') {
      //   return '/login';
      // }
      // if (isAuthenticated && !isOnboarded &&
      //     state.matchedLocation != '/onboarding') {
      //   return '/onboarding';
      // }
      // if (isAuthenticated && isAuthRoute) {
      //   return '/';
      // }
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

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
