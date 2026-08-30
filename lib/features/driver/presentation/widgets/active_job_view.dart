import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/job.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/driver_providers.dart';
import '../../data/driver_repository.dart';

const _activeJobStatusLabels = {
  'accepted': 'Accepted — ready to start',
  'en_route': 'En route to pickup',
  'arrived': 'Arrived at pickup',
  'passenger_on_board': 'Passenger on board',
};

/// Human-readable label for an active job's current status — shared with
/// [ActiveJobSummaryCard] so the Jobs tab's compact cards use the same
/// wording as the full step-controls view.
String activeJobStepLabel(String status) => _activeJobStatusLabels[status] ?? status;

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
    ref.invalidate(activeJobsProvider);
    ref.invalidate(openJobsProvider);
  }

  /// One call handles all four steps — same endpoint, just a different
  /// status string each time (confirmed live 26 Aug: strict sequence,
  /// 409s if called out of order, so there's no risk of this skipping a
  /// step even if tapped twice quickly).
  Future<void> _advanceTo(String status, {String? successMessage}) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(driverRepositoryProvider).updateJobStatus(widget.job.id, status: status);
      _refreshJobState();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
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

  static const List<(String, String, IconData, String, String?)> _steps = [
    ('accepted', 'Start Job', Icons.play_circle_outline, 'en_route', null),
    ('en_route', 'Arrived to Pickup', Icons.pin_drop, 'arrived', null),
    ('arrived', 'Passenger On Board', Icons.person, 'passenger_on_board', null),
    (
      'passenger_on_board',
      'Clear / Done',
      Icons.check_circle,
      'completed',
      'Trip completed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final pendingCancellation = job.hasPendingCancellation;
    (String, String, IconData, String, String?)? matchedStep;
    for (final s in _steps) {
      if (s.$1 == job.status) {
        matchedStep = s;
        break;
      }
    }
    final step = matchedStep;

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
                const SizedBox(height: 4),
                Text(
                  activeJobStepLabel(job.status),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
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
        // Start Job -> Arrived to Pickup -> Passenger On Board -> Clear/Done,
        // one button visible at a time for whichever step comes next.
        // Confirmed live 26 Aug: strict server-side sequence, matches _steps
        // above exactly.
        if (step != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting || pendingCancellation
                  ? null
                  : () => _advanceTo(step.$4, successMessage: step.$5),
              icon: Icon(step.$3),
              label: Text(step.$2),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSubmitting || pendingCancellation ? null : _cantComplete,
            child: const Text("Can't complete"),
          ),
        ),
      ],
    );
  }
}
