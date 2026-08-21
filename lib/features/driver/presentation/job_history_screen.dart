import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/driver_providers.dart';
import 'widgets/job_card.dart';

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            child: TabBar(
              tabs: [
                Tab(text: 'Paid'),
                Tab(text: 'Completed & Unpaid'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _HistoryList(paid: true),
                _HistoryList(paid: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myJobsProvider);
    final paymentsAsync = ref.watch(myPaymentsProvider);

    if (jobsAsync.isLoading || paymentsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (jobsAsync.hasError) {
      return Center(child: Text(jobsAsync.error.toString()));
    }
    if (paymentsAsync.hasError) {
      return Center(child: Text(paymentsAsync.error.toString()));
    }

    final jobs = jobsAsync.requireValue.where((j) => j.status == 'completed').toList();
    final payments = paymentsAsync.requireValue;
    final paymentByJobId = {for (final p in payments) p.jobId: p};

    final filtered = jobs.where((job) {
      final payment = paymentByJobId[job.id];
      final isPaid = payment?.isPaid ?? false;
      return isPaid == paid;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myJobsProvider);
        ref.invalidate(myPaymentsProvider);
        await Future.wait([
          ref.read(myJobsProvider.future),
          ref.read(myPaymentsProvider.future),
        ]);
      },
      child: filtered.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Center(
                    child: Text(paid ? 'No paid jobs yet' : 'Nothing outstanding'),
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final job = filtered[index];
                final payment = paymentByJobId[job.id];
                return JobCard(
                  job: job,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(job.fare)),
                      if (payment != null)
                        Text(
                          payment.isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            color: payment.isPaid ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
