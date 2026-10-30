import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Which band of [StatusColors] a pill uses.
enum StatusTone { waiting, open, assigned, live, done, stopped }

const _jobStatus = {
  'pending_approval': ('Awaiting approval', StatusTone.waiting),
  'open': ('Open', StatusTone.open),
  'accepted': ('Assigned', StatusTone.assigned),
  'en_route': ('En route', StatusTone.live),
  'arrived': ('Arrived', StatusTone.live),
  'passenger_on_board': ('On board', StatusTone.live),
  'completed': ('Completed', StatusTone.done),
  'cancelled': ('Cancelled', StatusTone.stopped),
};

/// Compact label + colour for a state. Colour is never the only signal:
/// every pill carries its word.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone, this.icon});

  /// A job's lifecycle status as shown everywhere in the app.
  factory StatusPill.job(String status, {Key? key}) {
    final (label, tone) = _jobStatus[status] ?? (status.replaceAll('_', ' '), StatusTone.open);
    return StatusPill(key: key, label: label, tone: tone);
  }

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = context.statusColors;
    final (bg, fg) = switch (tone) {
      StatusTone.waiting => (s.waiting, s.onWaiting),
      StatusTone.open => (s.open, s.onOpen),
      StatusTone.assigned => (s.assigned, s.onAssigned),
      StatusTone.live => (s.live, s.onLive),
      StatusTone.done => (s.done, s.onDone),
      StatusTone.stopped => (s.stopped, s.onStopped),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
