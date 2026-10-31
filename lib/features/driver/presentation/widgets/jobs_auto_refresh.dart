import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/driver_providers.dart';

/// Keeps the driver's job lists current without a pull-to-refresh: reloads
/// when the app comes back to the foreground and once a minute while it's
/// open, so a booking cancelled or reassigned elsewhere disappears even if
/// its push notification was missed. Pushes themselves refresh straight
/// away (PushNotificationService).
class JobsAutoRefresh extends ConsumerStatefulWidget {
  const JobsAutoRefresh({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<JobsAutoRefresh> createState() => _JobsAutoRefreshState();
}

class _JobsAutoRefreshState extends ConsumerState<JobsAutoRefresh> with WidgetsBindingObserver {
  static const _interval = Duration(minutes: 1);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_interval, (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    ref.invalidate(openJobsProvider);
    ref.invalidate(myJobsProvider);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
