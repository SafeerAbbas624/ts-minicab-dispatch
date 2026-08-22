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
    final paymentsAsync = ref.watch(myPaymentsProvider);

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (bucket) {
        // GET /payments/mine already returns paid/unpaid buckets with each
        // job embedded — no need to cross-reference /jobs/mine separately.
        final payments = paid ? bucket.paid : bucket.unpaid;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myPaymentsProvider);
            await ref.read(myPaymentsProvider.future);
          },
          child: payments.isEmpty
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
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final job = payment.job;
                    if (job == null) {
                      return _PaymentOnlyCard(payment: payment);
                    }
                    return JobCard(
                      job: job,
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatCurrency(payment.amount)),
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
      },
    );
  }
}

class _PaymentOnlyCard extends StatelessWidget {
  const _PaymentOnlyCard({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(formatCurrency(payment.amount)),
        subtitle: Text(payment.isPaid ? 'Paid' : 'Unpaid'),
      ),
    );
  }
}
