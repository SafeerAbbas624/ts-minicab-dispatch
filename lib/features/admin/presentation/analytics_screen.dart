import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminAnalyticsProvider),
        child: analyticsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(error.toString())),
          data: (analytics) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(label: 'Total drivers', value: '${analytics.totalDrivers}'),
              _StatCard(label: 'Active drivers', value: '${analytics.activeDrivers}'),
              _StatCard(label: 'Open jobs', value: '${analytics.openJobs}'),
              _StatCard(
                label: 'Completed jobs this week',
                value: '${analytics.completedJobsThisWeek}',
              ),
              _StatCard(
                label: 'Revenue this month',
                value: formatCurrency(analytics.totalRevenueThisMonth),
              ),
              _StatCard(
                label: 'Outstanding payments',
                value: formatCurrency(analytics.outstandingPayments),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

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
