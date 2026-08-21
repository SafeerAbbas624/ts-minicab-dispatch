import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.role,
    this.driverApprovalStatus,
  });

  const AuthState.initial() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final UserRole? role;
  final DriverApprovalStatus? driverApprovalStatus;

  AuthState copyWith({
    AuthStatus? status,
    UserRole? role,
    DriverApprovalStatus? driverApprovalStatus,
    bool clearDriverApprovalStatus = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      driverApprovalStatus:
          clearDriverApprovalStatus ? null : (driverApprovalStatus ?? this.driverApprovalStatus),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref)
      : _secureStorage = _ref.read(secureStorageProvider),
        _repository = _ref.read(authRepositoryProvider),
        super(const AuthState.initial()) {
    _restoreSession();
    _ref.listen<int>(sessionExpiredProvider, (previous, next) {
      if (previous != null && next != previous) {
        forceLogout();
      }
    });
  }

  final Ref _ref;
  final SecureStorage _secureStorage;
  final AuthRepository _repository;

  Future<void> _restoreSession() async {
    final token = await _secureStorage.readToken();
    final roleStr = await _secureStorage.readRole();
    if (token == null || roleStr == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    final role = UserRole.fromApi(roleStr);
    state = AuthState(status: AuthStatus.authenticated, role: role);
    if (role.isDriverFamily) {
      await refreshDriverApprovalStatus();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _repository.login(email: email, password: password);
    await _secureStorage.saveSession(token: result.token, role: result.role);
    final role = UserRole.fromApi(result.role);
    state = AuthState(status: AuthStatus.authenticated, role: role);
    if (role.isDriverFamily) {
      await refreshDriverApprovalStatus();
    }
  }

  /// Called right after OTP verification, in case the backend already
  /// activates the account rather than requiring a separate login. If this
  /// throws (e.g. no session yet), the signup flow falls back to sending the
  /// user to the login screen instead.
  Future<void> refreshDriverApprovalStatus() async {
    try {
      final driver = await _repository.fetchMyDriverProfile();
      state = state.copyWith(driverApprovalStatus: driver.status);
    } on ApiException {
      // Leave approval status unknown; the pending screen shows a generic
      // "check back later" message rather than crashing the app.
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String forename,
    required String surname,
    required String phoneNumber,
  }) {
    return _repository.signup(
      email: email,
      password: password,
      forename: forename,
      surname: surname,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> verifyOtp({required String email, required String otp}) {
    return _repository.verifyOtp(email: email, otp: otp);
  }

  Future<void> requestPasswordReset({required String email}) {
    return _repository.requestPasswordReset(email: email);
  }

  Future<void> resetPassword({required String token, required String newPassword}) {
    return _repository.resetPassword(token: token, newPassword: newPassword);
  }

  Future<void> requestAccountDeletion() {
    return _repository.requestAccountDeletion();
  }

  Future<void> logout() async {
    await _secureStorage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Same as logout but triggered by a 401 from ApiClient rather than a user
  /// action — no server call, since the token is already dead.
  void forceLogout() {
    _secureStorage.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
