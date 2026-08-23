import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return Column(
      children: [
        Expanded(child: IndexedStack(index: index, children: _tabs)),
        NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => ref.read(paymentsSubTabIndexProvider.notifier).state = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.pending_actions), label: 'Unpaid'),
            NavigationDestination(icon: Icon(Icons.done_all), label: 'Paid'),
          ],
        ),
      ],
    );
  }
}
