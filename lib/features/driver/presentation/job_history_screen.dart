import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
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

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (jobs) {
        // Two separate backend quirks to work around here, confirmed live
        // against the real API:
        // 1. /payments/mine's "unpaid" bucket is structurally always empty
        //    — a Payment row is only ever created at the moment something
        //    is marked paid, never when a job completes.
        // 2. /jobs/mine's nested `payment` isn't reliable either — it comes
        //    back null even for jobs that ARE genuinely paid (verified:
        //    /payments/mine's own "paid" bucket and the admin-facing
        //    /admin/jobs both correctly show a payment for the same job).
        // So: /payments/mine's "paid" bucket is the one reliable source for
        // what's actually paid; /jobs/mine is the reliable source for the
        // full completed-job list. Cross-reference by job id instead of
        // trusting either endpoint's own paid/unpaid split.
        final paidByJobId = paymentsAsync.maybeWhen(
          data: (bucket) => {for (final p in bucket.paid) p.jobId: p},
          orElse: () => const <String, Payment>{},
        );
        final completed = jobs.where((j) => j.status == 'completed');
        final relevant = completed.where((j) {
          final isPaid = paidByJobId.containsKey(j.id);
          return paid ? isPaid : !isPaid;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myJobsProvider);
            ref.invalidate(myPaymentsProvider);
            await Future.wait(
                [ref.read(myJobsProvider.future), ref.read(myPaymentsProvider.future)]);
          },
          child: relevant.isEmpty
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
                  itemCount: relevant.length,
                  itemBuilder: (context, index) {
                    final job = relevant[index];
                    final payment = paidByJobId[job.id];
                    final isPaid = payment != null;
                    return JobCard(
                      job: job,
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatCurrency(payment?.amount ?? job.fare)),
                          Text(
                            isPaid ? 'Paid' : 'Unpaid',
                            style: TextStyle(
                              color: isPaid ? Colors.green : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
