import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/driver_providers.dart';
import 'earnings_screen.dart';
import 'job_history_screen.dart';
import 'jobs_tab_screen.dart';
import 'driver_settings_screen.dart';
import 'widgets/pending_approval_view.dart';

/// Gates the whole driver shell on whether job endpoints are actually
/// reachable. The backend has no "approval status" field on the session —
/// it 403s job-related calls for a not-yet-approved/suspended/rejected
/// driver, with the reason in the response body, so that's the real signal.
class DriverShell extends ConsumerWidget {
  const DriverShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openJobsAsync = ref.watch(openJobsProvider);

    return openJobsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) {
        if (error is ApiException && error.isForbidden) {
          return PendingApprovalView(
            message: error.message,
            onRefresh: () => ref.invalidate(openJobsProvider),
          );
        }
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(openJobsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      data: (_) => const _DriverShellBody(),
    );
  }
}

class _DriverShellBody extends StatefulWidget {
  const _DriverShellBody();

  @override
  State<_DriverShellBody> createState() => _DriverShellBodyState();
}

class _DriverShellBodyState extends State<_DriverShellBody> {
  int _index = 0;

  static const _titles = ['Jobs', 'History', 'Earnings', 'Settings'];
  static const _tabs = [
    JobsTabScreen(),
    JobHistoryScreen(),
    EarningsScreen(),
    DriverSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
