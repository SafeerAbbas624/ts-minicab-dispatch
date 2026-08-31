import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/delete_account_info_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/privacy_policy_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/terms_conditions_screen.dart';
import '../../features/driver/presentation/driver_shell.dart';
import '../../features/admin/presentation/admin_shell.dart';

const _authFlowPrefixes = [
  '/login',
  '/signup',
  '/otp',
  '/forgot-password',
  '/reset-password',
];

/// Reference pages that must stay reachable by direct URL no matter who's
/// logged in — Play/App Store reviewers, and Google's Data Safety form
/// specifically, link straight to these. Previously these lived in the same
/// list as the auth-flow routes below and were only ever checked in the
/// `unauthenticated` branch, so an already-logged-in browser (e.g. a stale
/// session from earlier testing) skipped the check entirely and got bounced
/// straight to /admin or /driver instead of ever seeing the page.
const _alwaysPublicPrefixes = ['/privacy-policy', '/terms', '/delete-account'];

bool _isAuthFlowRoute(String loc) => _authFlowPrefixes.any((p) => loc.startsWith(p));
bool _isAlwaysPublicRoute(String loc) => _alwaysPublicPrefixes.any((p) => loc.startsWith(p));

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) => notifyListeners());
  }
}

/// Role decides which top-level area a user lands in. Driver *approval*
/// status is NOT gated here — the backend signals "not approved yet" as a
/// 403 on job-related endpoints, not a field on the session, so that's
/// handled inline inside DriverShell instead of blocking routing.
String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authControllerProvider);
  final loc = state.matchedLocation;

  // Checked first, before any auth-status branch — these pages stay
  // reachable by direct URL regardless of whether anyone's logged in.
  if (_isAlwaysPublicRoute(loc)) return null;

  if (auth.status == AuthStatus.checking) {
    return loc == '/splash' ? null : '/splash';
  }

  if (auth.status == AuthStatus.unauthenticated) {
    return _isAuthFlowRoute(loc) ? null : '/login';
  }

  final role = auth.role!;
  if (role.isAdminFamily) {
    return loc.startsWith('/admin') ? null : '/admin';
  }

  return loc.startsWith('/driver') ? null : '/driver';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(
        path: '/otp',
        builder: (context, state) => OtpScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: '/delete-account',
        builder: (context, state) => const DeleteAccountInfoScreen(),
      ),
      GoRoute(
        path: '/driver',
        builder: (context, state) => const DriverShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
    ],
  );
});
