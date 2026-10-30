import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/connectivity.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/route_block.dart';
import 'widgets/call_operator_button.dart';
import '../application/driver_providers.dart';
import '../data/driver_repository.dart';

/// Shown before a driver accepts an open job — full details up front, per
/// spec, rather than a blind accept.
class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.job});

  final Job job;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isAccepting = false;

  Future<void> _accept() async {
    setState(() => _isAccepting = true);
    try {
      await ref.read(driverRepositoryProvider).acceptJob(widget.job.id);
      ref.invalidate(openJobsProvider);
      // activeJobsProvider derives from myJobsProvider (ref.watch(myJobsProvider.future))
      // — invalidating activeJobsProvider alone just re-runs it against the
      // same stale cached myJobsProvider data, so the newly-accepted job
      // never shows up as active until something else invalidates
      // myJobsProvider too. Confirmed live: accepting a job left the Jobs tab
      // stuck on the open-jobs list instead of showing the new active job.
      ref.invalidate(myJobsProvider);
      ref.invalidate(activeJobsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isConflict) {
        ref.invalidate(openJobsProvider);
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Job already taken'),
            content: const Text('Someone else got this one. The list has been refreshed.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final pickup = toLondon(job.pickupDatetime);
    final time = '${pickup.hour.toString().padLeft(2, '0')}:${pickup.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: Text(job.bookingRef.isEmpty ? 'Job details' : job.bookingRef)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(time, style: t.displaySmall?.copyWith(fontFeatures: tabularFigures)),
                                  Text(formatDate(job.pickupDatetime), style: t.bodySmall),
                                ],
                              ),
                            ),
                            Text(formatCurrency(job.fare), style: t.headlineSmall?.copyWith(fontFeatures: tabularFigures)),
                          ],
                        ),
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
                        _DetailRow(label: 'Passenger', value: job.customerName),
                        if (job.vehicleClass != null) _DetailRow(label: 'Vehicle', value: job.vehicleClass!),
                        if (job.notes != null && job.notes!.isNotEmpty) _DetailRow(label: 'Notes', value: job.notes!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const CallOperatorButton(),
              ],
            ),
          ),
          Material(
            color: c.surfaceContainerLowest,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant))),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: AppTheme.primaryActionStyle(c),
                    onPressed: _isAccepting || !isOnline(ref) ? null : _accept,
                    child: _isAccepting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Accept job'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
