import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_token_repository.dart';

/// Registers this device's FCM token with the backend on login/app start and
/// again on every token refresh, per the spec.
///
/// NOT wired up yet — call [PushNotificationService.initialize] from
/// main.dart once google-services.json / GoogleService-Info.plist exist and
/// Firebase.initializeApp() is safe to call. Doing that before the config
/// files exist breaks the Android build (the Gradle Google Services plugin
/// needs google-services.json to be present).
class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) {
      await _register(token);
    }

    messaging.onTokenRefresh.listen(_register);
  }

  Future<void> _register(String deviceToken) {
    final platform = Platform.isIOS ? 'ios' : 'android';
    return _ref
        .read(pushTokenRepositoryProvider)
        .register(deviceToken: deviceToken, platform: platform);
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});
