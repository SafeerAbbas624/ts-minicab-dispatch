import 'package:flutter/material.dart';

import '../../../../core/models/job.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import 'active_job_view.dart';

/// One of the driver's current jobs in the strip at the top of the Jobs
/// tab. Navy, so a job in hand reads differently from the open jobs below
/// it at a glance; the orange marker is the current step. Tapping opens
/// [ActiveJobScreen] with the step controls.
class ActiveJobSummaryCard extends StatelessWidget {
  const ActiveJobSummaryCard({super.key, required this.job, this.onTap});

  final Job job;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Brand.navy700 : Brand.navy800;
    const fg = Colors.white;
    final fgMuted = Colors.white.withValues(alpha: 0.72);
    final pickup = toLondon(job.pickupDatetime);
    final time = '${pickup.hour.toString().padLeft(2, '0')}:${pickup.minute.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 290,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: job.hasPendingCancellation ? const Color(0xFFFFB4AB) : Brand.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        job.hasPendingCancellation ? 'Cancellation under review' : activeJobStepLabel(job.status),
                        style: t.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: fgMuted),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(time, style: t.headlineSmall?.copyWith(color: fg, fontFeatures: tabularFigures)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        job.bookingRef,
                        style: t.labelMedium?.copyWith(color: fgMuted, fontFeatures: tabularFigures),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      formatCurrency(job.fare),
                      style: t.titleSmall?.copyWith(color: fg, fontFeatures: tabularFigures),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  job.pickupLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: fg),
                ),
                Text(
                  'to ${job.dropoffLocation}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: fgMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
