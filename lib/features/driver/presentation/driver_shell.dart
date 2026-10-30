import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity.dart';
import '../../../core/widgets/responsive_nav_scaffold.dart';
import '../application/driver_providers.dart';
import '../application/location_sharing.dart';
import 'earnings_screen.dart';
import 'job_history_screen.dart';
import 'jobs_tab_screen.dart';
import 'driver_settings_screen.dart';

/// The bottom nav is always shown, regardless of approval status — a
/// not-yet-approved driver still needs to reach Settings > Documents to
/// upload their verification documents, which is the only way an admin ever
/// gets anything to review. Only the Jobs tab itself gates on approval (see
/// JobsTabScreen), since job-related endpoints are the only ones that 403
/// for a pending/suspended/rejected driver — this used to gate the whole
/// shell, which meant a newly-signed-up driver had no way to reach Documents
/// at all.
class DriverShell extends ConsumerWidget {
  const DriverShell({super.key});

  static bool _askedThisSession = false;

  static const _titles = ['Jobs', 'History', 'Earnings', 'Settings'];
  static const _tabs = [
    JobsTabScreen(),
    JobHistoryScreen(),
    EarningsScreen(),
    DriverSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(driverTabIndexProvider);

    // Live location follows the driver's jobs: on from "Start Job" until the
    // job is completed or handed back, off otherwise.
    ref.listen(activeJobsProvider, (_, next) {
      next.whenData((jobs) async {
        final live = liveTrackingJob(jobs);
        final sharing = ref.read(locationSharingProvider);
        await sharing.syncWith(live);
        // A job already under way (e.g. the app was reopened mid-journey)
        // but nothing shared: ask once per app session instead of waiting
        // for a Start job tap that will never come.
        if (live != null && sharing.sharingJobId == null && !_askedThisSession && context.mounted) {
          _askedThisSession = true;
          await sharing.enableFor(context, live);
        }
      });
    });
    // Back online: pull fresh state rather than trusting what was on screen.
    ref.listen(isOnlineProvider, (prev, next) {
      if (prev?.valueOrNull == false && next.valueOrNull == true) {
        ref.invalidate(openJobsProvider);
        ref.invalidate(myJobsProvider);
        ref.invalidate(activeJobsProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: _nav(index, ref)),
        ],
      ),
    );
  }

  Widget _nav(int index, WidgetRef ref) {
    return ResponsiveNavScaffold(
        selectedIndex: index,
        onSelect: (i) => ref.read(driverTabIndexProvider.notifier).state = i,
        destinations: const [
          NavItem(icon: Icons.work_outline, label: 'Jobs'),
          NavItem(icon: Icons.history, label: 'History'),
          NavItem(icon: Icons.payments_outlined, label: 'Earnings'),
          NavItem(icon: Icons.settings_outlined, label: 'Settings'),
        ],
        body: IndexedStack(index: index, children: _tabs),
    );
  }
}
