import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dispatch/core/widgets/responsive_nav_scaffold.dart';

void main() {
  Widget harness() => MaterialApp(
        home: Scaffold(
          body: ResponsiveNavScaffold(
            selectedIndex: 0,
            onSelect: (_) {},
            destinations: const [
              NavItem(icon: Icons.work_outline, label: 'Jobs'),
              NavItem(icon: Icons.history, label: 'History'),
            ],
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Post Job'),
            ),
            body: const Text('body content'),
          ),
        ),
      );

  testWidgets('renders a bottom NavigationBar below the desktop breakpoint', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('body content'), findsOneWidget);
    expect(find.text('Post Job'), findsOneWidget);
  });

  testWidgets('renders a side NavigationRail at/above the desktop breakpoint', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('body content'), findsOneWidget);
    expect(find.text('Post Job'), findsOneWidget);
  });
}
