import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/driver_providers.dart';
import 'job_detail_screen.dart';
import 'widgets/active_job_view.dart';
import 'widgets/job_card.dart';

class JobsTabScreen extends ConsumerWidget {
  const JobsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeJobAsync = ref.watch(activeJobProvider);

    return activeJobAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(activeJobProvider),
      ),
      data: (activeJob) {
        if (activeJob != null) {
          return ActiveJobView(job: activeJob);
        }
        return const _OpenJobsList();
      },
    );
  }
}

class _OpenJobsList extends ConsumerWidget {
  const _OpenJobsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openJobsAsync = ref.watch(openJobsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(openJobsProvider);
        await ref.read(openJobsProvider.future);
      },
      child: openJobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(openJobsProvider),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: const Center(child: Text('No open jobs right now')),
                ),
              ),
            );
          }
          return ListView.builder(
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
