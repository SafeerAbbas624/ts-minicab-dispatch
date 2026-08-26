import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/job.dart';

final _dayLabelFormat = DateFormat('EEE d MMM');

/// Buckets [jobs] into exactly 3 day-wise groups for the driver's Jobs tab:
/// today (including any overdue/edge-case job, so nothing silently
/// vanishes), the next distinct date that has a job, and everything from
/// the date after that onward. Always exactly 3 buckets — no "4th tab"
/// problem — with labels only populated once there's a real date to show.
class JobDayGroups {
  const JobDayGroups({
    required this.today,
    required this.next,
    required this.nextLabel,
    required this.later,
    required this.laterLabel,
  });

  final List<Job> today;
  final List<Job> next;
  final String? nextLabel;
  final List<Job> later;
  final String? laterLabel;
}

JobDayGroups groupJobsByDay(List<Job> jobs, DateTime now) {
  final today = DateUtils.dateOnly(now);
  final tomorrow = today.add(const Duration(days: 1));

  final todayJobs = <Job>[];
  final byFutureDate = <DateTime, List<Job>>{};
  for (final job in jobs) {
    final date = DateUtils.dateOnly(job.pickupDatetime);
    if (!date.isAfter(today)) {
      todayJobs.add(job);
    } else {
      byFutureDate.putIfAbsent(date, () => []).add(job);
    }
  }

  final futureDates = byFutureDate.keys.toList()..sort();

  final nextDate = futureDates.isNotEmpty ? futureDates.first : null;
  final laterDates = futureDates.length > 1 ? futureDates.sublist(1) : const <DateTime>[];

  final nextJobs = nextDate != null ? byFutureDate[nextDate]! : <Job>[];
  final laterJobs = [for (final d in laterDates) ...byFutureDate[d]!];

  int byPickup(Job a, Job b) => a.pickupDatetime.compareTo(b.pickupDatetime);
  todayJobs.sort(byPickup);
  nextJobs.sort(byPickup);
  laterJobs.sort(byPickup);

  String labelFor(DateTime date) =>
      date == tomorrow ? 'Tomorrow' : _dayLabelFormat.format(date);

  return JobDayGroups(
    today: todayJobs,
    next: nextJobs,
    nextLabel: nextDate != null ? labelFor(nextDate) : null,
    later: laterJobs,
    laterLabel: laterDates.isEmpty
        ? null
        : laterDates.length == 1
            ? labelFor(laterDates.first)
            : '${labelFor(laterDates.first)}+',
  );
}
