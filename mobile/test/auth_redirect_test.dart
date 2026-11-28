import 'package:bookie_ai/core/router/app_router.dart';
import 'package:bookie_ai/data/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('signed-out users are sent to login from protected routes', () {
    expect(authRedirect(AuthStatus.unauthenticated, '/'), '/login');
    expect(authRedirect(AuthStatus.unauthenticated, '/accounts/123'), '/login');
  });

  test('public routes and signed-in users are left alone', () {
    expect(authRedirect(AuthStatus.unauthenticated, '/login'), isNull);
    expect(authRedirect(AuthStatus.unauthenticated, '/register'), isNull);
    expect(authRedirect(AuthStatus.authenticated, '/'), isNull);
    // Before the splash screen has checked auth, don't redirect.
    expect(authRedirect(AuthStatus.initial, '/'), isNull);
  });
}
