import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

/// Bumped whenever a request comes back 401 (dead/expired token). AuthController
/// listens to this instead of ApiClient depending on AuthController directly,
/// which would create a provider import cycle.
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    secureStorage: ref.watch(secureStorageProvider),
    onUnauthorized: () {
      ref.read(sessionExpiredProvider.notifier).state++;
    },
  );
});
