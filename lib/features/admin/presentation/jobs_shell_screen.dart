import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import 'accepted_jobs_screen.dart';
import 'cancellation_requests_screen.dart';
import 'completed_jobs_screen.dart';
import 'job_posting_screen.dart';
import 'pending_jobs_screen.dart';
import 'website_jobs_queue_screen.dart';

class JobsShellScreen extends ConsumerWidget {
  const JobsShellScreen({super.key});

  // Index order also referenced by dashboard_screen.dart's stat-card
  // shortcuts — keep both in sync if this changes. Cancellations was
  // appended at the end (index 5) specifically so those existing shortcut
  // indices didn't need to move.
  static const _tabs = [
    JobPostingScreen(),
    WebsiteJobsQueueScreen(),
    PendingJobsScreen(),
    AcceptedJobsScreen(),
    CompletedJobsScreen(),
    CancellationRequestsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(jobsSubTabIndexProvider);
    return Stack(
      children: [
        Column(
          children: [
            Expanded(child: IndexedStack(index: index, children: _tabs)),
            NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => ref.read(jobsSubTabIndexProvider.notifier).state = i,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.add_road), label: 'Post a Job'),
                NavigationDestination(icon: Icon(Icons.language), label: 'Website Jobs'),
                NavigationDestination(icon: Icon(Icons.local_taxi_outlined), label: 'Active Jobs'),
                NavigationDestination(icon: Icon(Icons.badge_outlined), label: 'Accepted'),
                NavigationDestination(icon: Icon(Icons.task_alt), label: 'Completed'),
                NavigationDestination(icon: Icon(Icons.report_gmailerrorred), label: 'Cancellations'),
              ],
            ),
          ],
        ),
        // The bottom nav has no room for a 7th destination, so a floating
        // "Post a Job" bubble (WhatsApp-style) gives one-tap access from
        // every other sub-tab instead — hidden on the Post a Job tab itself
        // since it'd be redundant there. This screen has no Scaffold of its
        // own (it's a drawer destination inside AdminShell's), so the FAB is
        // positioned by hand rather than via Scaffold's floatingActionButton
        // slot — same pattern as TflExportScreen.
        if (index != 0)
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton(
              onPressed: () => ref.read(jobsSubTabIndexProvider.notifier).state = 0,
              tooltip: 'Post a Job',
              child: const Icon(Icons.add_road),
            ),
          ),
      ],
    );
  }
}
