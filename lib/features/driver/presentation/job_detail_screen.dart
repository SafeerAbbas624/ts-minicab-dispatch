import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DetailRow(label: 'Pickup time', value: formatDateTime(job.pickupDatetime)),
            _DetailRow(label: 'Pickup', value: job.pickupLocation),
            _DetailRow(label: 'Dropoff', value: job.dropoffLocation),
            _DetailRow(label: 'Customer', value: job.customerName),
            _DetailRow(label: 'Contact', value: job.customerContact),
            _DetailRow(label: 'Fare', value: formatCurrency(job.fare)),
            if (job.notes != null && job.notes!.isNotEmpty)
              _DetailRow(label: 'Notes', value: job.notes!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isAccepting ? null : _accept,
                child: _isAccepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept Job'),
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
