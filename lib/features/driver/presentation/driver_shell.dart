import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/driver_providers.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      body: IndexedStack(index: index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => ref.read(driverTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.work_outline), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
