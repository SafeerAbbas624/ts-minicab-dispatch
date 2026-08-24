import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import 'job_edit_screen.dart';
import 'widgets/job_detail_dialog.dart';

/// Website-sourced jobs waiting on admin review before they go live to
/// drivers. Confirmed via the backend's own API reference: JobStatus
/// includes "pending_approval", website jobs start in that status (only
/// admin-created jobs skip straight to "open"), and POST .../approve does
/// pending_approval → open. So this is a plain server-side status filter —
/// no need to fetch everything and filter by source client-side.
class WebsiteJobsQueueScreen extends ConsumerWidget {
  const WebsiteJobsQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider('pending_approval'));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (jobs) {
        if (jobs.isEmpty) {
          return const Center(child: Text('No jobs waiting for approval'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminJobsProvider('pending_approval')),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _QueueItem(job: jobs[index]),
          ),
        );
      },
    );
  }
}

class _QueueItem extends ConsumerStatefulWidget {
  const _QueueItem({required this.job});

  final Job job;

  @override
  ConsumerState<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends ConsumerState<_QueueItem> {
  bool _isSubmitting = false;

  Future<void> _approve() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).approveJob(widget.job.id);
      ref.invalidate(adminJobsProvider('pending_approval'));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => JobEditScreen(job: widget.job)),
    );
    if (saved == true) {
      ref.invalidate(adminJobsProvider('pending_approval'));
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
              Text(formatDateTime(job.pickupDatetime)),
              Text('${job.pickupLocation} → ${job.dropoffLocation}'),
              Text('${job.customerName} · ${formatCurrency(job.fare)}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(onPressed: _isSubmitting ? null : _edit, child: const Text('Edit')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _approve,
                    child: const Text('Approve'),
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
