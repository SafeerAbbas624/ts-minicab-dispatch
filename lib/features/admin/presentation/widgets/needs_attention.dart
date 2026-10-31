import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../application/admin_providers.dart';

/// Top of the dashboard: what the operating centre has to act on now, each
/// row one tap from the screen that resolves it. Counts come from the same
/// providers those screens use, so a number here always matches the list
/// it opens.
class NeedsAttention extends ConsumerWidget {
  const NeedsAttention({super.key, required this.onGo});

  final void Function({required int tab, int? jobsSub, int? driversSub, int? recordsSub}) onGo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;

    final pending = ref.watch(adminJobsProvider('pending_approval')).valueOrNull;
    final open = ref.watch(adminJobsProvider('open')).valueOrNull;
    final drivers = ref.watch(adminDriversProvider(null)).valueOrNull;
    final cancellations = ref.watch(adminCancellationRequestsProvider).valueOrNull;
    final records = ref.watch(adminComplianceSummaryProvider).valueOrNull;

    final soon = DateTime.now().add(const Duration(hours: 1));
    final unassignedSoon = open?.where((j) => j.pickupDatetime.isBefore(soon)).length;
    final expired = drivers?.where((d) => d.compliance?.hasExpired ?? false).length;
    final expiring = drivers?.where((d) => (d.compliance?.hasExpiringSoon ?? false) && !(d.compliance?.hasExpired ?? false)).length;
    final pendingDrivers = drivers?.where((d) => d.status == 'pending').length;
    final pendingCancellations = cancellations?.where((r) => r.status == 'pending').length;

    final rows = <_Row>[
      _Row('Bookings awaiting approval', pending?.length, StatusTone.waiting, () => onGo(tab: 1, jobsSub: 1)),
      _Row('Open jobs starting within an hour', unassignedSoon, StatusTone.stopped, () => onGo(tab: 1, jobsSub: 2)),
      _Row('Driver cancellation requests', pendingCancellations, StatusTone.waiting, () => onGo(tab: 1, jobsSub: 5)),
      _Row('Drivers with an expired document', expired, StatusTone.stopped, () => onGo(tab: 2, driversSub: 0)),
      _Row('Drivers with a document expiring in 30 days', expiring, StatusTone.waiting, () => onGo(tab: 2, driversSub: 0)),
      _Row('Driver applications to review', pendingDrivers, StatusTone.open, () => onGo(tab: 2, driversSub: 1)),
      _Row('Drivers to report to TfL (PHV/105, 14 days)', records?.phv105Due.length, StatusTone.stopped, () => onGo(tab: 2, driversSub: 0)),
      _Row('Open complaints', records?.openComplaints, StatusTone.waiting, () => onGo(tab: 5, recordsSub: 0)),
      _Row('Open lost property', records?.openLostProperty, StatusTone.open, () => onGo(tab: 5, recordsSub: 1)),
      _Row('Staff register entries incomplete (DBS)', records?.staffRegisterIncomplete.length, StatusTone.waiting, () => onGo(tab: 5, recordsSub: 2)),
    ];
    final loaded = rows.every((r) => r.count != null);
    final active = rows.where((r) => (r.count ?? 0) > 0).toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
              child: Text('Needs attention', style: t.titleMedium),
            ),
            if (!loaded)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: LinearProgressIndicator(minHeight: 3),
              )
            else if (active.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: context.statusColors.onDone),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nothing waiting. New bookings, cancellation requests and expiring documents will appear here.',
                        style: t.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final r in active) _AttentionTile(row: r),
            if (loaded && active.isNotEmpty) const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _Row {
  _Row(this.label, this.count, this.tone, this.onTap);
  final String label;
  final int? count;
  final StatusTone tone;
  final VoidCallback onTap;
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.row});

  final _Row row;

  @override
  Widget build(BuildContext context) {
    final s = context.statusColors;
    final t = Theme.of(context).textTheme;
    final (bg, fg) = switch (row.tone) {
      StatusTone.stopped => (s.stopped, s.onStopped),
      StatusTone.waiting => (s.waiting, s.onWaiting),
      _ => (s.open, s.onOpen),
    };
    return InkWell(
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Container(
              constraints: const BoxConstraints(minWidth: 44),
              height: 36,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${row.count}',
                style: t.titleMedium?.copyWith(color: fg, fontFeatures: tabularFigures),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(row.label, style: t.bodyLarge)),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
