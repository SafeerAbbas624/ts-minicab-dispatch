import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';

/// "Completed Jobs" sub-tab under the Jobs mega-tab — every completed job,
/// paid or not (mark-paid itself lives under the Payments tab now). Each
/// job's nested `payment` (added in the backend's bug-fix pass) is enough to
/// show a paid/unpaid badge without a separate lookup.
class CompletedJobsScreen extends ConsumerWidget {
  const CompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider('completed'));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (jobs) {
        if (jobs.isEmpty) {
          return const Center(child: Text('No completed jobs yet'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminJobsProvider('completed')),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final isPaid = job.payment?.isPaid ?? false;
              return Card(
                child: ListTile(
                  title: Text(formatDateTime(job.pickupDatetime)),
                  subtitle:
                      Text('${job.customerName} · ${job.pickupLocation} → ${job.dropoffLocation}'),
                  trailing: Chip(
                    label: Text(isPaid ? 'Paid' : 'Unpaid'),
                    backgroundColor:
                        (isPaid ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                    side: BorderSide(color: isPaid ? Colors.green : Colors.orange),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
