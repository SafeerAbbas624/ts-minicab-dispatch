import 'package:flutter_test/flutter_test.dart';

import 'package:dispatch/core/models/job.dart';
import 'package:dispatch/features/driver/presentation/widgets/job_day_grouping.dart';

Job _job(String id, DateTime pickup) => Job(
      id: id,
      pickupDatetime: pickup,
      pickupLocation: 'A',
      dropoffLocation: 'B',
      customerName: 'Customer',
      customerContact: '000',
      fare: 10,
      status: 'open',
    );

void main() {
  final now = DateTime(2026, 8, 27, 9);

  test('buckets today, tomorrow, and later, each sorted by pickup time', () {
    final jobToday2 = _job('today-2', DateTime(2026, 8, 27, 18));
    final jobToday1 = _job('today-1', DateTime(2026, 8, 27, 8));
    final jobTomorrow = _job('tomorrow', DateTime(2026, 8, 28, 10));
    final jobLater1 = _job('later-1', DateTime(2026, 8, 30, 9));
    final jobLater2 = _job('later-2', DateTime(2026, 9, 2, 9));

    final groups = groupJobsByDay(
      [jobToday2, jobToday1, jobTomorrow, jobLater2, jobLater1],
      now,
    );

    expect(groups.today.map((j) => j.id).toList(), ['today-1', 'today-2']);
    expect(groups.next.map((j) => j.id).toList(), ['tomorrow']);
    expect(groups.nextLabel, 'Tomorrow');
    expect(groups.later.map((j) => j.id).toList(), ['later-1', 'later-2']);
    expect(groups.laterLabel, 'Sun 30 Aug+');
  });

  test('an overdue open job still shown, bucketed into today', () {
    final overdue = _job('overdue', DateTime(2026, 8, 26, 8));
    final groups = groupJobsByDay([overdue], now);
    expect(groups.today.map((j) => j.id).toList(), ['overdue']);
  });

  test('no future jobs leaves next/later empty with null labels', () {
    final todayJob = _job('today', now);
    final groups = groupJobsByDay([todayJob], now);
    expect(groups.next, isEmpty);
    expect(groups.nextLabel, isNull);
    expect(groups.later, isEmpty);
    expect(groups.laterLabel, isNull);
  });

  test('single later date has no "+" suffix', () {
    final tomorrow = _job('tomorrow', DateTime(2026, 8, 28, 10));
    final oneLater = _job('later', DateTime(2026, 8, 30, 9));
    final groups = groupJobsByDay([tomorrow, oneLater], now);
    expect(groups.laterLabel, 'Sun 30 Aug');
  });
}
