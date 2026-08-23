import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/upload_validation.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';

/// One tab of PaymentsShellScreen — GET /admin/payments?status=paid|unpaid,
/// each row nesting the full job and a trimmed driver. Only the unpaid tab
/// gets a Mark Paid action; the paid tab is a read-only record.
class PaymentListScreen extends ConsumerWidget {
  const PaymentListScreen({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(adminPaymentsProvider(status));

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Text(status == 'paid' ? 'No paid jobs yet' : 'No unpaid jobs'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminPaymentsProvider(status)),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, index) =>
                _PaymentRow(payment: payments[index], isUnpaid: status == 'unpaid'),
          ),
        );
      },
    );
  }
}

class _PaymentRow extends ConsumerStatefulWidget {
  const _PaymentRow({required this.payment, required this.isUnpaid});

  final Payment payment;
  final bool isUnpaid;

  @override
  ConsumerState<_PaymentRow> createState() => _PaymentRowState();
}

class _PaymentRowState extends ConsumerState<_PaymentRow> {
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
    final payment = widget.payment;
    final job = payment.job;
    final driver = payment.driver;
    return Card(
      child: ListTile(
        title: Text(job != null ? formatDateTime(job.pickupDatetime) : 'Job ${payment.jobId}'),
        subtitle: Text([
          if (job != null) '${job.customerName} · ${job.pickupLocation} → ${job.dropoffLocation}',
          if (driver != null) 'Driver: ${driver.fullName}',
          if (!widget.isUnpaid && payment.paidAt != null)
            'Paid ${formatDateTime(payment.paidAt!)}',
        ].join('\n')),
        isThreeLine: true,
        trailing: widget.isUnpaid
            ? (_isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: _markPaid,
                    child: Text('Mark Paid  ${formatCurrency(payment.amount)}'),
                  ))
            : Chip(label: Text(formatCurrency(payment.amount))),
      ),
    );
  }
}
