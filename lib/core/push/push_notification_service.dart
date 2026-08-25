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
/// Tap routing: every push now carries `data.type` (a stable code, e.g.
/// `"job_completed"`) alongside the display `notification` block — see the
/// Push notifications reference section. Routes admin-side types straight to
/// the relevant tab. Driver-side types and the broadcast "new job available"
/// have no equivalent tab-index state to route into yet, so they just open
/// the app to wherever it already was.
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
        final type = response.payload;
        if (type != null) _routeFromType(type);
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
      payload: message.data['type'] as String?,
    );
  }

  void _routeFromMessage(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type != null) _routeFromType(type);
  }

  void _routeFromType(String type) {
    final role = _ref.read(authControllerProvider).role;
    if (role == null || !role.isAdminFamily) return;

    // tab indices match AdminShell's drawer order (Dashboard, Jobs, Drivers,
    // ...); jobsSub/driversSub match JobsShellScreen/DriversShellScreen's own
    // tab order — see admin_providers.dart's own index-order comments. Type
    // codes match the "To admins" table in the Push notifications reference
    // section; driver-facing types and the broadcast "new_job_available"
    // aren't listed here since there's no admin-side tab for them.
    switch (type) {
      case 'new_job_pending_approval':
        _goAdmin(tab: 1, jobsSub: 1);
      case 'new_driver_signup':
        _goAdmin(tab: 2, driversSub: 1);
      case 'account_deletion_requested':
      case 'document_uploaded':
        _goAdmin(tab: 2, driversSub: 0);
      case 'job_accepted':
      case 'job_started':
      case 'driver_arrived':
      case 'passenger_on_board':
        _goAdmin(tab: 1, jobsSub: 3);
      case 'job_released':
        _goAdmin(tab: 1, jobsSub: 2);
      case 'job_completed':
        _goAdmin(tab: 1, jobsSub: 4);
      case 'cancellation_requested':
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
