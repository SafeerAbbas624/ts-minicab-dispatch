import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import 'widgets/driver_picker_dialog.dart';
import 'widgets/job_detail_dialog.dart';

/// Jobs waiting for a driver to pick them up — status "open" only. Jobs a
/// driver has already accepted live on the separate Accepted Jobs sub-tab
/// instead, so this list doesn't mix "needs a driver" with "already has
/// one" the way the old combined Active Jobs tab did.
class PendingJobsScreen extends ConsumerWidget {
  const PendingJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider(null));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (allJobs) {
        final jobs = allJobs.where((j) => j.status == 'open').toList();
        if (jobs.isEmpty) {
          return const Center(child: Text('No open jobs'));
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

  Future<void> _assign() async {
    final selected = await showDriverPickerDialog(context, title: 'Assign to driver');
    if (selected == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).assignJob(widget.job.id, selected.id);
      ref.invalidate(adminJobsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Assigned to ${selected.fullName}')));
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
      child: InkWell(
        onTap: () => showJobDetailDialog(context, job),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : _assign,
                    child: const Text('Assign to driver'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isSubmitting ? null : _cancel,
                    style:
                        TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
