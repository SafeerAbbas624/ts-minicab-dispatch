import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';

class CompletedJobsScreen extends StatelessWidget {
  const CompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            child: TabBar(
              tabs: [
                Tab(text: 'Unpaid'),
                Tab(text: 'Paid'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _CompletedJobsList(paid: false),
                _CompletedJobsList(paid: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedJobsList extends ConsumerWidget {
  const _CompletedJobsList({required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No GET /admin/payments endpoint exists in the contract, so payment
    // state is assumed to live on the job itself: mark-paid presumably flips
    // job.status from "completed" to "paid". Flag if that's not how the
    // backend actually models it.
    final status = paid ? 'paid' : 'completed';
    final jobsAsync = ref.watch(adminJobsProvider(status));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (jobs) {
        if (jobs.isEmpty) {
          return Center(child: Text(paid ? 'No paid jobs yet' : 'Nothing outstanding'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminJobsProvider(status)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) =>
                _JobPaymentRow(job: jobs[index], paid: paid, listStatus: status),
          ),
        );
      },
    );
  }
}

class _JobPaymentRow extends ConsumerStatefulWidget {
  const _JobPaymentRow({required this.job, required this.paid, required this.listStatus});

  final Job job;
  final bool paid;
  final String listStatus;

  @override
  ConsumerState<_JobPaymentRow> createState() => _JobPaymentRowState();
}

class _JobPaymentRowState extends ConsumerState<_JobPaymentRow> {
  bool _isSubmitting = false;

  Future<void> _markPaid() async {
    final attachSlip = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as paid'),
        content: const Text('Attach a transaction slip photo/file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No slip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Attach slip'),
          ),
        ],
      ),
    );
    if (attachSlip == null) return;

    File? slipFile;
    if (attachSlip) {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (picked?.path != null) slipFile = File(picked!.path!);
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminRepositoryProvider).markPaid(widget.job.id, transactionSlip: slipFile);
      ref.invalidate(adminJobsProvider(widget.listStatus));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    return Card(
      child: ListTile(
        title: Text(formatDateTime(job.pickupDatetime)),
        subtitle: Text('${job.customerName} · ${job.pickupLocation} → ${job.dropoffLocation}'),
        trailing: widget.paid
            ? Text(formatCurrency(job.fare))
            : _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: _markPaid,
                    child: Text('Mark Paid  ${formatCurrency(job.fare)}'),
                  ),
      ),
    );
  }
}
