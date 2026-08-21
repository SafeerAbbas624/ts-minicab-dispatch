import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/job.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/driver_providers.dart';
import '../../data/driver_repository.dart';

class ActiveJobView extends ConsumerStatefulWidget {
  const ActiveJobView({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<ActiveJobView> createState() => _ActiveJobViewState();
}

class _ActiveJobViewState extends ConsumerState<ActiveJobView> {
  bool _isSubmitting = false;

  void _refreshJobState() {
    ref.invalidate(myJobsProvider);
    ref.invalidate(activeJobProvider);
    ref.invalidate(openJobsProvider);
  }

  Future<void> _markArrived() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(driverRepositoryProvider).updateJobStatus(widget.job.id, status: 'arrived');
      _refreshJobState();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _markCompleted() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(driverRepositoryProvider)
          .updateJobStatus(widget.job.id, status: 'completed');
      _refreshJobState();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Trip completed')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cantComplete() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Can't complete this job"),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Release Job'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(driverRepositoryProvider).releaseJob(widget.job.id, reason: reason);
      _refreshJobState();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job released')));
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
    final hasArrived = job.status == 'arrived';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Job', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Text(formatDateTime(job.pickupDatetime)),
                const SizedBox(height: 4),
                Text('${job.pickupLocation} → ${job.dropoffLocation}'),
                const SizedBox(height: 4),
                Text('${job.customerName} · ${job.customerContact}'),
                const SizedBox(height: 4),
                Text(formatCurrency(job.fare)),
                if (job.notes != null && job.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${job.notes}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!hasArrived)
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _markArrived,
            icon: const Icon(Icons.pin_drop),
            label: const Text('Arrived'),
          ),
        if (hasArrived)
          FilledButton.icon(
            onPressed: _isSubmitting ? null : _markCompleted,
            icon: const Icon(Icons.check_circle),
            label: const Text('Trip Completed'),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSubmitting ? null : _cantComplete,
          child: const Text("Can't complete"),
        ),
      ],
    );
  }
}
