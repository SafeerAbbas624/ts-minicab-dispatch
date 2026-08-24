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

  bool get _withinTwoHoursOfPickup =>
      widget.job.pickupDatetime.difference(DateTime.now()) < const Duration(hours: 2);

  Future<void> _cantComplete() async {
    final reason = _withinTwoHoursOfPickup
        ? await _showLateCancellationDialog()
        : await _showStandardCancelDialog();
    if (reason == null || reason.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(driverRepositoryProvider).requestCancellation(widget.job.id, reason: reason);
      _refreshJobState();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            _withinTwoHoursOfPickup ? 'Cancellation submitted for admin review' : 'Job released',
          ),
        ));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String?> _showStandardCancelDialog() {
    final reasonController = TextEditingController();
    return showDialog<String>(
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
  }

  /// Copy matches docs/BACKEND_REQUESTS.md's drafted professional tone for
  /// the sub-2-hour cancellation warning.
  Future<String?> _showLateCancellationDialog() {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelling this close to pickup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This job is due within 2 hours. Cancelling now may leave us unable to '
              "arrange another driver in time, so this won't cancel the job "
              'immediately — it will be sent to an admin for review.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Please explain why you need to cancel. If the cancellation is '
              'approved, it may result in a penalty on your account.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
              autofocus: true,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Submit for review'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final hasArrived = job.status == 'arrived';
    final pendingCancellation = job.hasPendingCancellation;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pendingCancellation)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top, color: Theme.of(context).colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pending cancellation — awaiting admin review. This job stays '
                      'assigned to you until reviewed.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (pendingCancellation) const SizedBox(height: 12),
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
            onPressed: _isSubmitting || pendingCancellation ? null : _markArrived,
            icon: const Icon(Icons.pin_drop),
            label: const Text('Arrived'),
          ),
        if (hasArrived)
          FilledButton.icon(
            onPressed: _isSubmitting || pendingCancellation ? null : _markCompleted,
            icon: const Icon(Icons.check_circle),
            label: const Text('Trip Completed'),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isSubmitting || pendingCancellation ? null : _cantComplete,
          child: const Text("Can't complete"),
        ),
      ],
    );
  }
}
