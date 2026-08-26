import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dispatch/core/models/admin_driver_detail.dart';
import 'package:dispatch/core/models/admin_models.dart';
import 'package:dispatch/core/models/driver.dart';
import 'package:dispatch/features/admin/application/admin_providers.dart';
import 'package:dispatch/features/admin/presentation/driver_queue_screen.dart';

void main() {
  final summary = AdminDriverSummary(
    id: 'driver-1',
    forename: 'Alex',
    surname: 'Driver',
    email: 'alex@example.com',
    status: 'pending',
    accountStatus: 'active',
  );

  final detail = AdminDriverDetail(
    driver: Driver(
      id: 'driver-1',
      email: 'alex@example.com',
      forename: 'Alex',
      surname: 'Driver',
      phoneNumber: '+44 7000 000000',
      approvalStatus: DriverApprovalStatus.pending,
      accountStatus: DriverAccountStatus.active,
    ),
    documents: const [],
    notes: const [],
    bankDetails: BankDetails(),
  );

  testWidgets('selecting a driver row on desktop renders their detail pane', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminDriversProvider('pending').overrideWith((ref) => Future.value([summary])),
          adminDriverDetailProvider('driver-1').overrideWith((ref) => Future.value(detail)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DriverQueueScreen(status: 'pending')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    // Nothing selected yet — detail pane shows the placeholder, not a crash.
    expect(find.text('Select a row to see details'), findsOneWidget);

    await tester.tap(find.text('Alex Driver'));
    await tester.pumpAndSettle();

    // Regression check: DriverDetailView used to be a bare ListView, which
    // throws "unbounded height" when nested inside the pane's own
    // SingleChildScrollView, leaving the pane blank instead of showing this.
    // Email appears twice (table cell + pane); phone only ever shows in the
    // pane, so it alone confirms the detail actually rendered.
    expect(find.text('alex@example.com'), findsNWidgets(2));
    expect(find.text('+44 7000 000000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
