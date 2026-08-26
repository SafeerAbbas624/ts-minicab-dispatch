import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_models.dart';
import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';

/// Renamed from Analytics — the default screen on admin launch. Every stat
/// card is a shortcut into the tab (and sub-tab) that explains the number,
/// driven by the same StateProviders AdminShell's drawer and the Jobs/
/// Drivers/Payments bottom nav bars read from.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _go(WidgetRef ref, {required int tab, int? jobsSub, int? driversSub, int? paymentsSub}) {
    if (jobsSub != null) ref.read(jobsSubTabIndexProvider.notifier).state = jobsSub;
    if (driversSub != null) ref.read(driversSubTabIndexProvider.notifier).state = driversSub;
    if (paymentsSub != null) ref.read(paymentsSubTabIndexProvider.notifier).state = paymentsSub;
    ref.read(adminTabIndexProvider.notifier).state = tab;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminAnalyticsProvider),
      child: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (analytics) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Confirmed 25 Aug (docs/BACKEND_REQUESTS.md item 8): GET
            // /admin/analytics deliberately excludes demo_admin/demo_driver
            // activity from every total below, unlike the Jobs/Payments
            // screens these cards link into — so the numbers here can look
            // "wrong" next to those screens during demo/reviewer account
            // use. Decided (Option C): keep both scopes as-is, just label
            // this one rather than hide or unify them.
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Excludes demo/reviewer account activity',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            // Grid instead of a stacked column above 600px — a single-column
            // list of stat cards wastes most of a desktop-width screen.
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 600 ? 2 : 1);
                const spacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final cards = [
                  _StatCard(
                    label: 'Total jobs',
                    value: '${analytics.totalJobs}',
                    icon: Icons.work_outline,
                    onTap: () => _go(ref, tab: 1, jobsSub: 2),
                  ),
                  _StatCard(
                    label: 'Open jobs',
                    value: '${analytics.openJobs}',
                    icon: Icons.pending_actions,
                    onTap: () => _go(ref, tab: 1, jobsSub: 2),
                  ),
                  _StatCard(
                    label: 'Completed jobs',
                    value: '${analytics.completedJobs}',
                    icon: Icons.task_alt,
                    onTap: () => _go(ref, tab: 1, jobsSub: 4),
                  ),
                  _StatCard(
                    label: 'Active approved drivers',
                    value: '${analytics.activeApprovedDrivers}',
                    icon: Icons.badge_outlined,
                    onTap: () => _go(ref, tab: 2, driversSub: 2),
                  ),
                  _StatCard(
                    label: 'Revenue paid',
                    value: formatCurrency(analytics.totalRevenuePaid),
                    icon: Icons.check_circle_outline,
                    onTap: () => _go(ref, tab: 3, paymentsSub: 1),
                  ),
                  _StatCard(
                    label: 'Outstanding unpaid',
                    value: formatCurrency(analytics.totalOutstandingUnpaid),
                    icon: Icons.hourglass_bottom,
                    onTap: () => _go(ref, tab: 3, paymentsSub: 0),
                  ),
                ];
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [for (final c in cards) SizedBox(width: itemWidth, child: c)],
                );
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text('Insights', style: Theme.of(context).textTheme.titleMedium),
            ),
            ..._buildInsights(analytics),
          ],
        ),
      ),
    );
  }

  /// Derived metrics computed client-side from the same totals the raw stat
  /// cards use — no extra API calls. Analytics only ever gives running
  /// totals (counts + two revenue sums), so these are the ratios/averages
  /// that totals alone can support; none of them assume data the endpoint
  /// doesn't actually provide (e.g. there's no paid-job *count*, only a
  /// paid revenue *sum*, so "average paid fare" isn't computable — average
  /// job value below deliberately uses billed revenue, not just paid).
  List<Widget> _buildInsights(AdminAnalytics a) {
    final totalBilled = a.totalRevenuePaid + a.totalOutstandingUnpaid;
    final completionRate = a.totalJobs > 0 ? a.completedJobs / a.totalJobs * 100 : 0.0;
    final collectionRate = totalBilled > 0 ? a.totalRevenuePaid / totalBilled * 100 : 0.0;
    final avgJobValue = a.completedJobs > 0 ? totalBilled / a.completedJobs : 0.0;
    final jobsPerDriver = a.activeApprovedDrivers > 0 ? a.totalJobs / a.activeApprovedDrivers : 0.0;
    final openShare = a.totalJobs > 0 ? a.openJobs / a.totalJobs * 100 : 0.0;

    return [
      _InsightCard(
        label: 'Job completion rate',
        value: '${completionRate.toStringAsFixed(1)}%',
        detail: '${a.completedJobs} of ${a.totalJobs} jobs completed',
      ),
      _InsightCard(
        label: 'Payment collection rate',
        value: '${collectionRate.toStringAsFixed(1)}%',
        detail: '${formatCurrency(a.totalRevenuePaid)} collected of ${formatCurrency(totalBilled)} billed',
      ),
      _InsightCard(
        label: 'Average job value',
        value: formatCurrency(avgJobValue),
        detail: 'Total billed ÷ completed jobs',
      ),
      _InsightCard(
        label: 'Jobs per active driver',
        value: jobsPerDriver.toStringAsFixed(1),
        detail: 'Total jobs ÷ active approved drivers',
      ),
      _InsightCard(
        label: 'Open jobs share',
        value: '${openShare.toStringAsFixed(1)}%',
        detail: 'Share of all jobs still waiting for a driver',
      ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleLarge),
        onTap: onTap,
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.label, required this.value, required this.detail});

  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.outline),
                  ),
                ],
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
