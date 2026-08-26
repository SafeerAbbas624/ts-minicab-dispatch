import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dispatch/core/models/job.dart';
import 'package:dispatch/features/admin/application/admin_providers.dart';
import 'package:dispatch/features/admin/presentation/pending_jobs_screen.dart';

void main() {
  final openJob = Job(
    id: 'job-1',
    pickupDatetime: DateTime(2026, 8, 26, 10),
    pickupLocation: 'Heathrow T5',
    dropoffLocation: 'Central London',
    customerName: 'Jane Doe',
    customerContact: '+44 7000 000000',
    fare: 45,
    status: 'open',
  );

  Widget harness() => ProviderScope(
        overrides: [
          adminJobsProvider(null).overrideWith((ref) => Future.value([openJob])),
        ],
        child: const MaterialApp(home: Scaffold(body: PendingJobsScreen())),
      );

  testWidgets('shows the mobile Card list below the desktop breakpoint', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsWidgets);
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('Jane Doe · £45.00'), findsOneWidget);
  });

  testWidgets('shows a DataTable at/above the desktop breakpoint', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);
  });
}
