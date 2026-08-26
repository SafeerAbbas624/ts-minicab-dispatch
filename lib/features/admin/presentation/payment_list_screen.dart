import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/upload_validation.dart';
import '../../../core/widgets/responsive_master_detail_list.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import 'widgets/job_detail_dialog.dart';

/// One tab of PaymentsShellScreen. The paid tab reads GET
/// /admin/payments?status=paid directly (reliable — a paid Payment row
/// always exists once something's been marked paid). The unpaid tab can't
/// use the equivalent status=unpaid call: the backend only ever creates a
/// Payment row at the moment something is marked paid, never when a job
/// completes, so that endpoint is structurally always empty regardless of
/// how many completed jobs are actually awaiting payment. Deriving unpaid
/// from GET /admin/jobs?status=completed's nested `payment` (null until
/// marked paid) instead means a job never silently disappears from view.
class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status == 'unpaid') {
      final jobsAsync = ref.watch(adminJobsProvider('completed'));
      return jobsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (jobs) {
          final unpaid = jobs.where((j) => !(j.payment?.isPaid ?? false)).toList();
          if (unpaid.isEmpty) {
            return const Center(child: Text('No unpaid jobs'));
          }
          final payments = [
            for (final job in unpaid)
              job.payment ?? Payment(id: job.id, jobId: job.id, amount: job.fare, isPaid: false, job: job),
          ];
          return _PaymentTable(
            payments: payments,
            isUnpaid: true,
            onRefresh: () async => ref.invalidate(adminJobsProvider('completed')),
          );
        },
      );
    }

    final paymentsAsync = ref.watch(adminPaymentsProvider('paid'));
    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(child: Text('No paid jobs yet'));
        }
        return _PaymentTable(
          payments: payments,
          isUnpaid: false,
          onRefresh: () async => ref.invalidate(adminPaymentsProvider('paid')),
        );
      },
    );
  }
}

class _PaymentTable extends StatelessWidget {
  const _PaymentTable({required this.payments, required this.isUnpaid, required this.onRefresh});

  final List<Payment> payments;
  final bool isUnpaid;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final mobileList = RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: payments.length,
        itemBuilder: (context, index) => _PaymentRow(payment: payments[index], isUnpaid: isUnpaid),
      ),
    );
    return ResponsiveMasterDetailList<Payment>(
      items: payments,
      itemKey: (p) => p.id,
      mobileList: mobileList,
      detailFor: (p) =>
          p.job != null ? JobDetailView(job: p.job!) : const Text('No job details available'),
      columns: const [
        DataColumn(label: Text('Pickup')),
        DataColumn(label: Text('Customer / Route')),
        DataColumn(label: Text('Driver')),
        DataColumn(label: Text('Amount / Action')),
      ],
      cellsFor: (p) => [
        DataCell(Text(p.job != null ? formatDateTime(p.job!.pickupDatetime) : 'Job ${p.jobId}')),
        DataCell(Text(
          p.job != null ? '${p.job!.customerName} · ${p.job!.pickupLocation} → ${p.job!.dropoffLocation}' : '—',
        )),
        DataCell(Text(p.driver?.fullName ?? '—')),
        DataCell(isUnpaid
            ? _MarkPaidAction(payment: p)
            : Chip(label: Text(formatCurrency(p.amount)))),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment, required this.isUnpaid});

  final Payment payment;
  final bool isUnpaid;

  @override
  Widget build(BuildContext context) {
    final job = payment.job;
    final driver = payment.driver;
    return Card(
      child: ListTile(
        onTap: job != null ? () => showJobDetailDialog(context, job) : null,
        title: Text(job != null ? formatDateTime(job.pickupDatetime) : 'Job ${payment.jobId}'),
        subtitle: Text([
          if (job != null) '${job.customerName} · ${job.pickupLocation} → ${job.dropoffLocation}',
          if (driver != null) 'Driver: ${driver.fullName}',
          if (!isUnpaid && payment.paidAt != null) 'Paid ${formatDateTime(payment.paidAt!)}',
        ].join('\n')),
        isThreeLine: true,
        trailing: isUnpaid
            ? _MarkPaidAction(payment: payment)
            : Chip(label: Text(formatCurrency(payment.amount))),
      ),
    );
  }
}

/// "Mark Paid" button (with optional transaction-slip upload) — shared
/// between the mobile card's trailing widget and the desktop table's
/// Amount/Action column.
class _MarkPaidAction extends ConsumerStatefulWidget {
  const _MarkPaidAction({required this.payment});

  final Payment payment;

  @override
  ConsumerState<_MarkPaidAction> createState() => _MarkPaidActionState();
}

class _MarkPaidActionState extends ConsumerState<_MarkPaidAction> {
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
        allowedExtensions: allowedUploadExtensions,
      );
      if (picked?.path != null) {
        final candidate = File(picked!.path!);
        final validationError = await validateUploadFile(candidate);
        if (validationError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
          }
          return;
        }
        slipFile = candidate;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .markPaid(widget.payment.jobId, transactionSlip: slipFile);
      ref.invalidate(adminPaymentsProvider('unpaid'));
      ref.invalidate(adminPaymentsProvider('paid'));
      // Dashboard's revenue-paid/outstanding-unpaid cards, and the Jobs
      // tab's Completed sub-tab (which shows a paid/unpaid badge from each
      // job's own nested `payment`), both read separate providers — without
      // invalidating those too, they'd show stale data until a manual
      // refresh even though the payment actually changed.
      ref.invalidate(adminAnalyticsProvider);
      ref.invalidate(adminJobsProvider('completed'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked paid')));
      }
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
    return _isSubmitting
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : FilledButton(
            onPressed: _markPaid,
            child: Text('Mark Paid  ${formatCurrency(widget.payment.amount)}'),
          );
  }
}
