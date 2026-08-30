import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dispatch/core/models/job.dart';
import 'package:dispatch/features/driver/application/driver_providers.dart';
import 'package:dispatch/features/driver/presentation/jobs_tab_screen.dart';

Job _job(String id, DateTime pickup, String customerName) => Job(
      id: id,
      pickupDatetime: pickup,
      pickupLocation: 'Heathrow',
      dropoffLocation: 'Central London',
      customerName: customerName,
      customerContact: '000',
      fare: 20,
      status: 'open',
    );

void main() {
  testWidgets('open jobs split into Today/next/later tabs', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayJob = _job('today', today.add(const Duration(hours: 18)), 'Today Customer');
    final nextJob =
        _job('next', today.add(const Duration(days: 1, hours: 9)), 'Next Customer');
    final laterJob =
        _job('later', today.add(const Duration(days: 5, hours: 9)), 'Later Customer');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeJobsProvider.overrideWith((ref) => Future.value(const [])),
          openJobsProvider.overrideWith((ref) => Future.value([todayJob, nextJob, laterJob])),
        ],
        child: const MaterialApp(home: Scaffold(body: JobsTabScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    // The next bucket is exactly tomorrow in this fixture, which gets the
    // friendly "Tomorrow" label instead of a formatted date.
    expect(find.text('Tomorrow'), findsOneWidget);

    // Today's tab is selected by default and shows only today's job.
    expect(find.text('Today Customer · 000'), findsOneWidget);
    expect(find.text('Next Customer · 000'), findsNothing);
    expect(find.text('Later Customer · 000'), findsNothing);

    // Second tab (tomorrow / "next").
    final tabs = find.descendant(of: find.byType(TabBar), matching: find.byType(Tab));
    await tester.tap(tabs.at(1));
    await tester.pumpAndSettle();
    expect(find.text('Next Customer · 000'), findsOneWidget);

    // Third tab (later — the far-future job, on its own real date label,
    // not the "Later" placeholder since there is data for it).
    await tester.tap(tabs.at(2));
    await tester.pumpAndSettle();
    expect(find.text('Later Customer · 000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
