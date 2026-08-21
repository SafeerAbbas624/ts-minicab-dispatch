import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_role.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated }

class AuthState {
  const AuthState({required this.status, this.role});

  const AuthState.initial() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final UserRole? role;
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
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    state = AuthState(status: AuthStatus.authenticated, role: UserRole.fromApi(roleStr));
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _repository.login(email: email, password: password);
    await _secureStorage.saveSession(token: result.token, role: result.role);
    state = AuthState(status: AuthStatus.authenticated, role: UserRole.fromApi(result.role));
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
