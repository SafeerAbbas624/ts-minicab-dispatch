import 'package:flutter/material.dart';

import '../../../../core/models/job.dart';
import '../../../../core/utils/formatters.dart';
import 'active_job_view.dart';

/// Compact card for one of the driver's active jobs, shown in a horizontal
/// strip at the top of the Jobs tab. Tapping it is expected to push
/// [ActiveJobScreen] for the full step controls — same visual language as
/// [JobCard] (rounded card, formatted time/route/fare) but with a status
/// chip for the current step instead of a plain fare pill, since knowing
/// *where in the trip* each active job is at a glance is the whole point
/// of this card once a driver can hold more than one at once.
class ActiveJobSummaryCard extends StatelessWidget {
  const ActiveJobSummaryCard({super.key, required this.job, this.onTap});

  final Job job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 280,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activeJobStepLabel(job.status),
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: colors.outline),
                  ],
                ),
                if (job.hasPendingCancellation)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Chip(
                      label: const Text('Pending cancellation'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colors.errorContainer,
                      labelStyle: TextStyle(color: colors.onErrorContainer, fontSize: 11),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  formatDateTime(job.pickupDatetime),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.pickupLocation} → ${job.dropoffLocation}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.customerName} · ${formatCurrency(job.fare)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
