import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../providers/core_providers.dart';

/// POST /push-tokens is documented under the driver section of the API
/// contract, but the spec also calls for admin push (job-needs-approval
/// alerts) — so this is kept role-agnostic and callable from either panel
/// rather than tied to the driver repository. Flag with the backend session
/// if admin push actually needs a different endpoint.
class PushTokenRepository {
  PushTokenRepository(this._client);
  final ApiClient _client;

  Future<void> register({required String deviceToken, required String platform}) {
    return _client.post('/push-tokens', data: {
      'device_token': deviceToken,
      'platform': platform,
    });
  }
}

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  return PushTokenRepository(ref.watch(apiClientProvider));
});
