import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/job.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/admin_providers.dart';

/// Full detail popup for a job — used from every admin job list so every
/// card is tappable, not just the ones with an explicit action button.
/// When [job] has an assigned driver, fetches and shows that driver's
/// contact info too (the job payload itself only ever carries the driver's
/// id, never a name).
Future<void> showJobDetailDialog(BuildContext context, Job job) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Job details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _Row('Status', job.status),
                _Row('Pickup', formatDateTime(job.pickupDatetime)),
                _Row('From', job.pickupLocation),
                _Row('To', job.dropoffLocation),
                _Row('Customer', job.customerName),
                _Row('Contact', job.customerContact),
                _Row('Fare', formatCurrency(job.fare)),
                if (job.source != null) _Row('Source', job.source!),
                if (job.notes != null && job.notes!.isNotEmpty) _Row('Notes', job.notes!),
                if (job.payment != null)
                  _Row('Payment', job.payment!.isPaid ? 'Paid' : 'Unpaid to driver'),
                if (job.acceptedByDriverId != null) ...[
                  const Divider(height: 32),
                  Text('Driver', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _DriverInfo(driverId: job.acceptedByDriverId!),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DriverInfo extends ConsumerWidget {
  const _DriverInfo({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminDriverDetailProvider(driverId));
    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stack) => Text('Could not load driver: $error'),
      data: (detail) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row('Name', detail.driver.fullName),
          _Row('Phone', detail.driver.phoneNumber),
          _Row('Email', detail.driver.email),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
