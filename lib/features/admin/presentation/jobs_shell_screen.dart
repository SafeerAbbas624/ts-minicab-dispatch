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
    return Column(
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
    );
  }
}
