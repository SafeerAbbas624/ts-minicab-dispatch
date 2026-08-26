import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_nav_scaffold.dart';
import '../application/admin_providers.dart';
import 'payment_list_screen.dart';

class PaymentsShellScreen extends ConsumerWidget {
  const PaymentsShellScreen({super.key});

  static const _tabs = [
    PaymentListScreen(status: 'unpaid'),
    PaymentListScreen(status: 'paid'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(paymentsSubTabIndexProvider);
    return ResponsiveNavScaffold(
      selectedIndex: index,
      onSelect: (i) => ref.read(paymentsSubTabIndexProvider.notifier).state = i,
      destinations: const [
        NavItem(icon: Icons.pending_actions, label: 'Unpaid'),
        NavItem(icon: Icons.done_all, label: 'Paid'),
      ],
      body: IndexedStack(index: index, children: _tabs),
    );
  }
}
