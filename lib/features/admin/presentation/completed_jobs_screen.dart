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

/// GET /admin/payments?status=unpaid is the dedicated payments-first view —
/// each row nests the full job and a trimmed driver, so marking a job paid
/// and invalidating this provider correctly drops it off the list (no more
/// local-only "just marked paid" tracking needed).
class CompletedJobsScreen extends ConsumerWidget {
  const CompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(adminPaymentsProvider('unpaid'));

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(child: Text('No unpaid jobs'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminPaymentsProvider('unpaid')),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, index) => _PaymentRow(payment: payments[index]),
          ),
        );
      },
    );
  }
}

class _PaymentRow extends ConsumerStatefulWidget {
  const _PaymentRow({required this.payment});

  final Payment payment;

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
        ].join('\n')),
        isThreeLine: driver != null,
        trailing: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton(
                onPressed: _markPaid,
                child: Text('Mark Paid  ${formatCurrency(payment.amount)}'),
              ),
      ),
    );
  }
}
