import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_nav_scaffold.dart';
import '../application/admin_providers.dart';
import 'driver_queue_screen.dart';

/// Bottom nav bar (side rail on wide/desktop screens) replaces the old top
/// ChoiceChip row for picking an approval-status filter — matches the driver
/// panel's own tab pattern.
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
    return ResponsiveNavScaffold(
      maxContentWidth: 1600,
      selectedIndex: index,
      onSelect: (i) => ref.read(driversSubTabIndexProvider.notifier).state = i,
      destinations: const [
        NavItem(icon: Icons.list_alt, label: 'All'),
        NavItem(icon: Icons.hourglass_empty, label: 'Pending'),
        NavItem(icon: Icons.check_circle_outline, label: 'Approved'),
        NavItem(icon: Icons.block_outlined, label: 'Rejected'),
      ],
      body: IndexedStack(index: index, children: _tabs),
    );
  }
}
