import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_nav_scaffold.dart';
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
    // Post a Job (index 0 in _tabs) has no nav-bar destination of its own —
    // that's now the FAB's job, freeing up room in the bar for the other
    // five. The bar's own selectedIndex is offset by one to account for
    // that: nav position 0 = _tabs index 1, etc. Clamped so nothing throws
    // while the Post a Job screen itself is showing (index 0), where no nav
    // destination truly applies.
    final navSelectedIndex = (index - 1).clamp(0, 4);
    return ResponsiveNavScaffold(
      // Wider than the default 1100 — the desktop view here is a data table
      // + detail pane, not a single centered column, so it benefits from
      // more of the screen than a typical content page would.
      maxContentWidth: 1600,
      selectedIndex: navSelectedIndex,
      onSelect: (i) => ref.read(jobsSubTabIndexProvider.notifier).state = i + 1,
      destinations: const [
        // "Website"/"Active" rather than "Website Jobs"/"Active Jobs" — with
        // 5 destinations the full labels wrapped and overlapped the next
        // item on narrow phones. Every label reads fine without "Jobs" since
        // the tab is already titled "Jobs".
        NavItem(icon: Icons.language, label: 'Website'),
        NavItem(icon: Icons.local_taxi_outlined, label: 'Active'),
        NavItem(icon: Icons.badge_outlined, label: 'Accepted'),
        NavItem(icon: Icons.task_alt, label: 'Completed'),
        NavItem(icon: Icons.report_gmailerrorred, label: 'Cancellations'),
      ],
      floatingActionButton: FloatingActionButton.extended(
        // admin_shell.dart keeps every top-level screen mounted at once via
        // IndexedStack, so this FAB coexists in the tree with TflExportScreen's —
        // without a unique tag both fall back to Flutter's shared default
        // FloatingActionButton hero tag and collide.
        heroTag: 'jobsShellPostJobFab',
        onPressed: () => ref.read(jobsSubTabIndexProvider.notifier).state = 0,
        icon: const Icon(Icons.add_road),
        label: const Text('Post Job'),
      ),
      body: IndexedStack(index: index, children: _tabs),
    );
  }
}
