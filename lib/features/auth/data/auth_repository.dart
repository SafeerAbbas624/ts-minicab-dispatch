import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart';

class LoginResult {
  LoginResult({required this.token, required this.role});
  final String token;
  final String role;
}

class AuthRepository {
  AuthRepository(this._client);
  final ApiClient _client;

  Future<void> signup({
    required String email,
    required String password,
    required String forename,
    required String surname,
    required String phoneNumber,
  }) async {
    await _client.post('/auth/driver/signup', data: {
      'email': email,
      'password': password,
      'forename': forename,
      'surname': surname,
      'phone_number': phoneNumber,
    });
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    await _client.post('/auth/driver/verify-otp', data: {'email': email, 'otp': otp});
  }

  Future<LoginResult> login({required String email, required String password}) async {
    final res = await _client.post('/auth/login', data: {'email': email, 'password': password});
    final data = res.data as Map<String, dynamic>;
    return LoginResult(token: data['token'] as String, role: data['role'] as String);
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _client.post('/auth/request-password-reset', data: {'email': email});
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    await _client.post('/auth/reset-password', data: {'token': token, 'new_password': newPassword});
  }

  Future<void> requestAccountDeletion() async {
    await _client.post('/account/delete-request');
  }

  Future<Driver> fetchMyDriverProfile() async {
    final res = await _client.get('/drivers/me');
    return Driver.fromJson(res.data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
