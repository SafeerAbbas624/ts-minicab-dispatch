import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/otp_screen.dart';
import '../../features/auth/presentation/pending_approval_screen.dart';
import '../../features/auth/presentation/privacy_policy_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/driver/presentation/driver_shell.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../models/driver.dart';

const _publicPrefixes = [
  '/login',
  '/signup',
  '/otp',
  '/forgot-password',
  '/reset-password',
  '/privacy-policy',
];

bool _isPublicRoute(String loc) => _publicPrefixes.any((p) => loc.startsWith(p));

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) => notifyListeners());
  }
}

String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authControllerProvider);
  final loc = state.matchedLocation;

  if (auth.status == AuthStatus.checking) {
    return loc == '/splash' ? null : '/splash';
  }

  if (auth.status == AuthStatus.unauthenticated) {
    return _isPublicRoute(loc) ? null : '/login';
  }

  final role = auth.role!;
  if (role.isAdminFamily) {
    return loc.startsWith('/admin') ? null : '/admin';
  }

  // driver family
  final approved = auth.driverApprovalStatus == DriverApprovalStatus.approved;
  if (!approved) {
    return loc == '/driver/pending' ? null : '/driver/pending';
  }
  if (loc.startsWith('/driver') && loc != '/driver/pending') return null;
  return '/driver';
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
        path: '/driver/pending',
        builder: (context, state) => const PendingApprovalScreen(),
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
