import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/responsive_nav_scaffold.dart';
import '../../application/admin_providers.dart';
import 'complaints_screen.dart';
import 'lost_property_screen.dart';
import 'staff_register_screen.dart';

/// TfL records an inspector asks to see besides bookings, drivers and
/// vehicles: complaints, lost property and the staff register.
class RecordsShellScreen extends ConsumerWidget {
  const RecordsShellScreen({super.key});

  static const _tabs = [ComplaintsScreen(), LostPropertyScreen(), StaffRegisterScreen()];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(recordsSubTabIndexProvider);
    return ResponsiveNavScaffold(
      selectedIndex: index,
      onSelect: (i) => ref.read(recordsSubTabIndexProvider.notifier).state = i,
      destinations: const [
        NavItem(icon: Icons.report_outlined, label: 'Complaints'),
        NavItem(icon: Icons.inventory_2_outlined, label: 'Lost property'),
        NavItem(icon: Icons.badge_outlined, label: 'Staff register'),
      ],
      body: IndexedStack(index: index, children: _tabs),
    );
  }
}
