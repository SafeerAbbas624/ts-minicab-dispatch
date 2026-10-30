import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/models/job.dart';
import '../data/driver_repository.dart';

/// Statuses during which the passenger's tracking page shows the driver —
/// same set as the backend's LIVE_TRACKING_STATUSES.
const liveTrackingStatuses = {'en_route', 'arrived', 'passenger_on_board'};

/// The job whose location is currently being shared, if any.
Job? liveTrackingJob(List<Job> activeJobs) {
  for (final job in activeJobs) {
    if (liveTrackingStatuses.contains(job.status)) return job;
  }
  return null;
}

/// Google Play's "prominent disclosure" rule: say what's collected and why,
/// in-app, before the system permission prompt. Returns true once location
/// permission is granted (asking only if needed).
Future<bool> ensureLocationPermission(BuildContext context) async {
  if (kIsWeb) return false;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
    return true;
  }
  if (permission == LocationPermission.deniedForever) {
    if (context.mounted) await _showSettingsHint(context);
    return false;
  }
  if (!context.mounted) return false;
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.location_on_outlined),
      title: const Text('Share your location on jobs'),
      content: const Text(
        'TS Minicab collects your location from when you tap "Start Job" until '
        'you complete or hand back that job — including while the app is in the '
        'background, for example when you use a navigation app.\n\n'
        'It is shown only to that job\'s passenger on their private tracking '
        'page and kept in the booking record, as required for our TfL licence. '
        'Your location is never collected when you are not on a job.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Not now')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Continue')),
      ],
    ),
  );
  if (agreed != true) return false;
  permission = await Geolocator.requestPermission();
  return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
}

Future<void> _showSettingsHint(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location is turned off'),
        content: const Text(
          'Passengers can\'t see you arriving. Allow location for TS Minicab in your '
          'phone\'s Settings to turn live tracking back on.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Later')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

/// Streams the device location to `POST /jobs/:id/location` while a job is
/// live, at most every [_minInterval]. On Android this runs as a foreground
/// service with an ongoing notification, so it keeps working while the
/// driver uses a navigation app; it stops as soon as no job is live.
class LocationSharingController {
  LocationSharingController(this._repository);

  final DriverRepository _repository;
  static const _minInterval = Duration(seconds: 10);

  StreamSubscription<Position>? _subscription;
  String? _jobId;
  DateTime? _lastSent;

  String? get sharingJobId => _jobId;

  Future<void> syncWith(Job? liveJob) async {
    if (kIsWeb) return;
    if (liveJob == null) return stop();
    if (_jobId == liveJob.id && _subscription != null) return;
    await stop();

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return;

    _jobId = liveJob.id;
    _subscription = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      _send,
      onError: (Object e) => debugPrint('[location] stream error: $e'),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _jobId = null;
    _lastSent = null;
  }

  Future<void> _send(Position p) async {
    final jobId = _jobId;
    if (jobId == null) return;
    final now = DateTime.now();
    if (_lastSent != null && now.difference(_lastSent!) < _minInterval) return;
    _lastSent = now;
    try {
      await _repository.sendLocation(
        jobId,
        lat: p.latitude,
        lng: p.longitude,
        heading: p.heading >= 0 ? p.heading : null,
        speed: p.speed >= 0 ? p.speed : null,
        accuracy: p.accuracy,
      );
    } catch (e) {
      // Offline or a transient error — the next fix will try again.
      debugPrint('[location] send failed: $e');
    }
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: _minInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Sharing your location with your passenger',
          notificationText: 'Stops automatically when you complete the job.',
          notificationChannelName: 'Live job tracking',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 15,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15);
  }
}

final locationSharingProvider = Provider<LocationSharingController>((ref) {
  final controller = LocationSharingController(ref.watch(driverRepositoryProvider));
  ref.onDispose(controller.stop);
  return controller;
});
