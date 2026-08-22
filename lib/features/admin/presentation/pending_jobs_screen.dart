import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';

const _activeStatuses = {'open', 'accepted', 'arrived'};

class PendingJobsScreen extends ConsumerWidget {
  const PendingJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider(null));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (allJobs) {
        final jobs = allJobs.where((j) => _activeStatuses.contains(j.status)).toList();
        if (jobs.isEmpty) {
          return const Center(child: Text('No active jobs'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminJobsProvider(null)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _JobRow(job: jobs[index]),
          ),
        );
      },
    );
  }
}

class _JobRow extends ConsumerStatefulWidget {
  const _JobRow({required this.job});

  final Job job;

  @override
  ConsumerState<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends ConsumerState<_JobRow> {
  bool _isSubmitting = false;

  Future<void> _cancel() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this job'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Cancel Job'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).cancelJob(widget.job.id, reason: reason);
      ref.invalidate(adminJobsProvider(null));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reassign() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).reassignJob(widget.job.id);
      ref.invalidate(adminJobsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job reopened for reassignment')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(formatDateTime(job.pickupDatetime))),
                Chip(label: Text(job.status), visualDensity: VisualDensity.compact),
              ],
            ),
            Text('${job.pickupLocation} → ${job.dropoffLocation}'),
            Text('${job.customerName} · ${formatCurrency(job.fare)}'),
            Text(
              // No accepted-driver name in the job payload, only an id
              // (currentDriverId) — the contract has no driver-lookup
              // endpoint to resolve it to a name, so this shows the id.
              job.acceptedByDriverId != null
                  ? 'Accepted by driver ${job.acceptedByDriverId}'
                  : 'Not yet accepted',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (job.status != 'open')
                  TextButton(
                    onPressed: _isSubmitting ? null : _reassign,
                    child: const Text('Reassign / Reopen'),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isSubmitting ? null : _cancel,
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
