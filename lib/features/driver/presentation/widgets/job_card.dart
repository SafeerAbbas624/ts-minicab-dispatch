import 'package:flutter/material.dart';

import '../../../../core/models/job.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/route_block.dart';

/// One job in a list: the pickup time is the headline (it's what a driver
/// decides on), then the route, then fare and vehicle. Readable at arm's
/// length; the whole card is the tap target.
class JobCard extends StatelessWidget {
  const JobCard({super.key, required this.job, this.onTap, this.trailing});

  final Job job;
  final VoidCallback? onTap;

  /// Replaces the fare in the top-right corner (e.g. a status pill).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final pickup = toLondon(job.pickupDatetime);
    final time = '${pickup.hour.toString().padLeft(2, '0')}:${pickup.minute.toString().padLeft(2, '0')}';
    final hasNotes = job.notes != null && job.notes!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
                        Text(time, style: t.headlineMedium?.copyWith(fontFeatures: tabularFigures)),
                        const SizedBox(height: 2),
                        Text(
                          [formatDate(job.pickupDatetime), if (job.bookingRef.isNotEmpty) job.bookingRef].join('  ·  '),
                          style: t.labelMedium?.copyWith(color: c.onSurfaceVariant, fontFeatures: tabularFigures),
                        ),
                      ],
                    ),
                  ),
                  trailing ??
                      Text(
                        formatCurrency(job.fare),
                        style: t.titleLarge?.copyWith(fontFeatures: tabularFigures),
                      ),
                ],
              ),
              const SizedBox(height: 16),
              RouteBlock(pickup: job.pickupLocation, vias: job.viaStops, dropoff: job.dropoffLocation, dense: true),
              const SizedBox(height: 14),
              Divider(color: c.outlineVariant.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 18, color: c.onSurfaceVariant),
                  const SizedBox(width: 6),
                  // Passenger name only — drivers never get the passenger's
                  // number (TfL: contact goes through the operating centre).
                  Expanded(
                    child: Text(
                      job.customerContact.isEmpty ? job.customerName : '${job.customerName} · ${job.customerContact}',
                      style: t.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (job.vehicleClass != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        job.vehicleClass!,
                        style: t.labelMedium?.copyWith(color: c.onSecondaryContainer),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasNotes) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sticky_note_2_outlined, size: 18, color: c.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        job.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
