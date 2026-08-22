import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/driver_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myPaymentsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myPaymentsProvider);
        await ref.read(myPaymentsProvider.future);
      },
      child: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (bucket) {
          final now = DateTime.now();
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final monthStart = DateTime(now.year, now.month, 1);

          final paid = bucket.paid;
          final totalPaid = paid.fold<double>(0, (sum, p) => sum + p.amount);
          final thisWeek = paid
              .where((p) => p.paidAt != null && p.paidAt!.isAfter(weekStart))
              .fold<double>(0, (sum, p) => sum + p.amount);
          final thisMonth = paid
              .where((p) => p.paidAt != null && p.paidAt!.isAfter(monthStart))
              .fold<double>(0, (sum, p) => sum + p.amount);
          final outstanding = bucket.unpaid.fold<double>(0, (sum, p) => sum + p.amount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(label: 'This week', value: formatCurrency(thisWeek)),
              _SummaryCard(label: 'This month', value: formatCurrency(thisMonth)),
              _SummaryCard(label: 'All-time paid', value: formatCurrency(totalPaid)),
              _SummaryCard(label: 'Outstanding', value: formatCurrency(outstanding)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
