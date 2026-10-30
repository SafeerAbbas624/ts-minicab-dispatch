import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/job.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/connectivity.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/route_block.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../application/driver_providers.dart';
import '../../application/location_sharing.dart';
import 'call_operator_button.dart';
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
    // Starting the job turns on live tracking for the passenger — ask for
    // location first (with the in-app disclosure). The job can still start
    // without it; the passenger just won't see the map.
    if (status == 'en_route') {
      final granted = await ensureLocationPermission(context);
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location is off — your passenger won\'t see you on the map.'),
        ));
      }
      if (!mounted) return;
    }
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
    ('accepted', 'Start job', Icons.play_arrow_rounded, 'en_route', null),
    ('en_route', 'Arrived at pickup', Icons.pin_drop_outlined, 'arrived', null),
    ('arrived', 'Passenger on board', Icons.person_outline, 'passenger_on_board', null),
    (
      'passenger_on_board',
      'Complete job',
      Icons.check_rounded,
      'completed',
      'Trip completed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final pendingCancellation = job.hasPendingCancellation;
    (String, String, IconData, String, String?)? matchedStep;
    for (final s in _steps) {
      if (s.$1 == job.status) {
        matchedStep = s;
        break;
      }
    }
    final step = matchedStep;
    final online = isOnline(ref);
    final sharing = liveTrackingStatuses.contains(job.status) &&
        ref.watch(locationSharingProvider).sharingJobId == job.id;
    final pickup = toLondon(job.pickupDatetime);
    final time = '${pickup.hour.toString().padLeft(2, '0')}:${pickup.minute.toString().padLeft(2, '0')}';
    final busy = _isSubmitting || pendingCancellation || !online;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              if (pendingCancellation) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: c.errorContainer, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top, color: c.onErrorContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cancellation under review by the operating centre. This job stays '
                          'assigned to you until it is reviewed.',
                          style: t.bodyMedium?.copyWith(color: c.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill.job(job.status),
                          const Spacer(),
                          Text(
                            job.bookingRef,
                            style: t.labelLarge?.copyWith(color: c.onSurfaceVariant, fontFeatures: tabularFigures),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(time, style: t.displaySmall?.copyWith(fontFeatures: tabularFigures)),
                      Text(formatDate(job.pickupDatetime), style: t.bodySmall),
                      const SizedBox(height: 20),
                      _StepTrack(status: job.status),
                      const SizedBox(height: 20),
                      RouteBlock(pickup: job.pickupLocation, dropoff: job.dropoffLocation, maxLines: null),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Column(
                    children: [
                      _Fact(icon: Icons.person_outline, label: 'Passenger', value: job.customerName),
                      _Fact(icon: Icons.payments_outlined, label: 'Fare', value: formatCurrency(job.fare)),
                      if (job.vehicleClass != null)
                        _Fact(icon: Icons.directions_car_outlined, label: 'Vehicle', value: job.vehicleClass!),
                      if (job.notes != null && job.notes!.isNotEmpty)
                        _Fact(icon: Icons.sticky_note_2_outlined, label: 'Notes', value: job.notes!),
                    ],
                  ),
                ),
              ),
              if (liveTrackingStatuses.contains(job.status)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      sharing ? Icons.my_location : Icons.location_disabled,
                      size: 18,
                      color: sharing ? context.statusColors.onDone : c.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sharing
                            ? 'Sharing your live location with the passenger'
                            : "Location not shared — the passenger can't see you on the map",
                        style: t.bodySmall?.copyWith(color: c.onSurface),
                      ),
                    ),
                    if (!sharing && !kIsWeb)
                      FilledButton.tonal(
                        onPressed: () async {
                          final granted = await ref.read(locationSharingProvider).enableFor(context, job);
                          if (!granted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Allow location for TS Minicab to share it with your passenger.'),
                            ));
                          }
                        },
                        child: const Text('Share'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              const CallOperatorButton(),
            ],
          ),
        ),
        // The next step sits in a fixed tray at the bottom of the screen,
        // within thumb reach, one button at a time. Strict server-side
        // sequence (confirmed live 26 Aug) matches _steps above exactly.
        Material(
          color: c.surfaceContainerLowest,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant))),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (step != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: AppTheme.primaryActionStyle(c),
                        onPressed: busy ? null : () => _advanceTo(step.$4, successMessage: step.$5),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : Icon(step.$3, size: 26),
                        label: Text(step.$2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: c.error),
                      onPressed: busy ? null : _cantComplete,
                      child: const Text("Can't complete this job"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Assigned → On the way → Arrived → On board, the current step in orange.
class _StepTrack extends StatelessWidget {
  const _StepTrack({required this.status});

  final String status;

  static const _labels = ['Assigned', 'On the way', 'Arrived', 'On board'];
  static const _order = ['accepted', 'en_route', 'arrived', 'passenger_on_board'];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final current = _order.indexOf(status);

    return Semantics(
      label: 'Progress: ${current >= 0 ? _labels[current] : status}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == _labels.length - 1 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i < current
                          ? c.primary
                          : i == current
                              ? c.tertiary
                              : c.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _labels[i],
                    style: t.labelSmall?.copyWith(
                      color: i <= current ? c.onSurface : c.onSurfaceVariant,
                      fontWeight: i == current ? FontWeight.w800 : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: c.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(width: 84, child: Text(label, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
          Expanded(child: Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
