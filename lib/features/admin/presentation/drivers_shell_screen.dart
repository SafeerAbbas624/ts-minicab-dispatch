import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import 'driver_queue_screen.dart';

/// Bottom nav bar replaces the old top ChoiceChip row for picking an
/// approval-status filter — matches the driver panel's own tab pattern.
class DriversShellScreen extends ConsumerWidget {
  const DriversShellScreen({super.key});

  static const _tabs = [
    DriverQueueScreen(status: null),
    DriverQueueScreen(status: 'pending'),
    DriverQueueScreen(status: 'approved'),
    DriverQueueScreen(status: 'rejected'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(driversSubTabIndexProvider);
    return Column(
      children: [
        Expanded(child: IndexedStack(index: index, children: _tabs)),
        NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => ref.read(driversSubTabIndexProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.list_alt), label: 'All'),
            NavigationDestination(icon: Icon(Icons.hourglass_empty), label: 'Pending'),
            NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Approved'),
            NavigationDestination(icon: Icon(Icons.block_outlined), label: 'Rejected'),
          ],
        ),
      ],
    );
  }
}
