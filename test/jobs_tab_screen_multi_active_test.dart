import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dispatch/core/models/job.dart';
import 'package:dispatch/features/driver/application/driver_providers.dart';
import 'package:dispatch/features/driver/presentation/active_job_screen.dart';
import 'package:dispatch/features/driver/presentation/jobs_tab_screen.dart';
import 'package:dispatch/features/driver/presentation/widgets/active_job_summary_card.dart';

Job _job(String id, DateTime pickup, String customerName, String status) => Job(
      id: id,
      pickupDatetime: pickup,
      pickupLocation: 'Heathrow',
      dropoffLocation: 'Central London',
      customerName: customerName,
      customerContact: '000',
      fare: 20,
      status: status,
    );

void main() {
  testWidgets('shows every active job alongside the still-browsable open-jobs list', (tester) async {
    final now = DateTime.now();
    final active1 = _job('active-1', now.add(const Duration(hours: 1)), 'Active One', 'accepted');
    final active2 = _job('active-2', now.add(const Duration(hours: 4)), 'Active Two', 'en_route');
    final openJob = _job('open-1', now.add(const Duration(hours: 2)), 'Open Customer', 'open');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeJobsProvider.overrideWith((ref) => Future.value([active1, active2])),
          openJobsProvider.overrideWith((ref) => Future.value([openJob])),
        ],
        child: const MaterialApp(home: Scaffold(body: JobsTabScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Both active jobs show as summary cards, not just one.
    expect(find.byType(ActiveJobSummaryCard), findsNWidgets(2));
    expect(find.text('Active One · £20.00'), findsOneWidget);
    expect(find.text('Active Two · £20.00'), findsOneWidget);

    // The open-jobs list is still reachable underneath — this is the whole
    // point of the change: holding an active job no longer hides it.
    expect(find.text('Open Customer · 000'), findsOneWidget);

    // Tapping an active job's summary card opens its full step controls.
    await tester.tap(find.text('Active One · £20.00'));
    await tester.pumpAndSettle();
    expect(find.byType(ActiveJobScreen), findsOneWidget);
    expect(find.text('Start Job'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
