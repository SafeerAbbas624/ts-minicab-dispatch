import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/application/admin_providers.dart';
import '../../features/auth/application/auth_controller.dart';
import 'push_token_repository.dart';

const _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Job & driver alerts',
  description: 'Job status changes, driver activity, and account updates',
  importance: Importance.high,
);

/// Registers this device's FCM token with the backend on login/app start and
/// again on every token refresh, per the spec. Called from
/// AuthController._registerPushToken() on both login and session restore.
///
/// Also handles the parts FCM doesn't do for free: Android never shows a
/// message that arrives while the app is in the foreground on its own (only
/// background/terminated messages get an automatic system tray entry), so
/// [FirebaseMessaging.onMessage] is used to surface those via
/// flutter_local_notifications instead. iOS *does* auto-display in the
/// foreground once [setForegroundNotificationPresentationOptions] opts in,
/// so the local-notifications path is Android-only.
///
/// Tap routing: the backend's notification payload is a plain
/// `{notification: {title, body}}` with no custom data keys yet (see
/// docs/BACKEND_REQUESTS.md), so there's nothing to route on except the
/// title text — matched here against the admin notification catalog to jump
/// straight to the relevant tab. Anything unmatched, or any driver-side
/// notification, just opens the app to wherever it already was; there's no
/// equivalent tab-index state on the driver side to route into yet.
class PushNotificationService {
  PushNotificationService(this._ref)
      : _localNotifications = FlutterLocalNotificationsPlugin();

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _listenersWired = false;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      await _initLocalNotifications();
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _register(token);
    }
    messaging.onTokenRefresh.listen(_register);

    // Guard against double-subscribing: AuthController calls initialize()
    // on both login and every session restore, but these listeners should
    // only ever be wired once per app process.
    if (!_listenersWired) {
      _listenersWired = true;
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      FirebaseMessaging.onMessageOpenedApp.listen(_routeFromMessage);
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) _routeFromMessage(initialMessage);
    }
  }

  Future<void> _initLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final title = response.payload;
        if (title != null) _routeFromTitle(title);
      },
    );
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || !Platform.isAndroid) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: notification.title,
    );
  }

  void _routeFromMessage(RemoteMessage message) {
    final title = message.notification?.title;
    if (title != null) _routeFromTitle(title);
  }

  void _routeFromTitle(String title) {
    final role = _ref.read(authControllerProvider).role;
    if (role == null || !role.isAdminFamily) return;

    // tab indices match AdminShell's drawer order (Dashboard, Jobs, Drivers,
    // ...); jobsSub/driversSub match JobsShellScreen/DriversShellScreen's own
    // tab order — see admin_providers.dart's own index-order comments.
    switch (title) {
      case 'New job pending approval':
        _goAdmin(tab: 1, jobsSub: 1);
      case 'New driver signup':
        _goAdmin(tab: 2, driversSub: 1);
      case 'Account deletion requested':
      case 'New document uploaded':
        _goAdmin(tab: 2, driversSub: 0);
      case 'Job accepted':
      case 'Driver arrived at pickup':
        _goAdmin(tab: 1, jobsSub: 3);
      case 'Job released back to open':
        _goAdmin(tab: 1, jobsSub: 2);
      case 'Job completed':
        _goAdmin(tab: 1, jobsSub: 4);
      case 'Cancellation request':
        _goAdmin(tab: 1, jobsSub: 5);
    }
  }

  void _goAdmin({required int tab, int? jobsSub, int? driversSub}) {
    if (jobsSub != null) _ref.read(jobsSubTabIndexProvider.notifier).state = jobsSub;
    if (driversSub != null) {
      _ref.read(driversSubTabIndexProvider.notifier).state = driversSub;
    }
    _ref.read(adminTabIndexProvider.notifier).state = tab;
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
