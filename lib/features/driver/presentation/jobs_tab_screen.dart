import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../application/driver_providers.dart';
import 'active_job_screen.dart';
import 'job_detail_screen.dart';
import 'widgets/active_job_summary_card.dart';
import 'widgets/job_card.dart';
import 'widgets/job_day_grouping.dart';
import 'widgets/pending_approval_view.dart';

class JobsTabScreen extends ConsumerWidget {
  const JobsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeJobsAsync = ref.watch(activeJobsProvider);

    return activeJobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        // The backend has no "approval status" field on the session — it
        // 403s job-related calls for a not-yet-approved/suspended/rejected
        // driver, with the reason in the response body, so that's the real
        // signal. Scoped to just this tab (not the whole shell) so a pending
        // driver can still reach Settings > Documents to upload what an
        // admin needs to review.
        if (error is ApiException && error.isForbidden) {
          return PendingApprovalView(
            message: error.message,
            onRefresh: () {
              ref.invalidate(myJobsProvider);
              ref.invalidate(activeJobsProvider);
            },
          );
        }
        return _ErrorView(
          message: error.toString(),
          // activeJobsProvider derives from myJobsProvider — if that's what
          // actually failed, invalidating only activeJobsProvider re-reads
          // the same cached failure instead of retrying the real request.
          onRetry: () {
            ref.invalidate(myJobsProvider);
            ref.invalidate(activeJobsProvider);
          },
        );
      },
      data: (activeJobs) {
        // A driver can hold more than one active job at once (as long as
        // they don't conflict in time, enforced server-side) — so unlike
        // before, the open-jobs list stays reachable even with active jobs
        // in progress, instead of being replaced by them.
        return Column(
          children: [
            if (activeJobs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Active Jobs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                height: 168,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: activeJobs.length,
                  itemBuilder: (context, index) {
                    final job = activeJobs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActiveJobSummaryCard(
                        job: job,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ActiveJobScreen(job: job)),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
            const Expanded(child: _OpenJobsList()),
          ],
        );
      },
    );
  }
}

class _OpenJobsList extends ConsumerWidget {
  const _OpenJobsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openJobsAsync = ref.watch(openJobsProvider);

    Future<void> refresh() async {
      ref.invalidate(openJobsProvider);
      await ref.read(openJobsProvider.future);
    }

    return openJobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(openJobsProvider),
      ),
      data: (jobs) {
        final groups = groupJobsByDay(jobs, DateTime.now());
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  const Tab(text: 'Today'),
                  Tab(text: groups.nextLabel ?? 'Upcoming'),
                  Tab(text: groups.laterLabel ?? 'Later'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _DayJobsList(jobs: groups.today, emptyMessage: 'No jobs today', onRefresh: refresh),
                    _DayJobsList(
                      jobs: groups.next,
                      emptyMessage: 'No jobs lined up yet',
                      onRefresh: refresh,
                    ),
                    _DayJobsList(
                      jobs: groups.later,
                      emptyMessage: 'Nothing further out yet',
                      onRefresh: refresh,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayJobsList extends StatelessWidget {
  const _DayJobsList({required this.jobs, required this.emptyMessage, required this.onRefresh});

  final List<Job> jobs;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: jobs.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(child: Text(emptyMessage)),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return JobCard(
                  job: job,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                  ),
                );
              },
            ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
