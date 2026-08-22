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

/// A Paid/Unpaid split isn't possible here: GET /admin/jobs returns
/// identical data for a completed-and-paid job and a completed-and-unpaid
/// one (confirmed against real seeded demo jobs — no payment field on the
/// job object at all), and there's no GET /admin/payments endpoint to look
/// it up separately. So this shows every completed job with a Mark Paid
/// action on each, rather than tabs that can't actually be populated
/// correctly. Flagged to the backend session: either the job list needs a
/// payment-status field, or a GET /admin/payments endpoint needs to exist.
class CompletedJobsScreen extends ConsumerWidget {
  const CompletedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(adminJobsProvider('completed'));

    return jobsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (jobs) {
        if (jobs.isEmpty) {
          return const Center(child: Text('No completed jobs yet'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminJobsProvider('completed')),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: jobs.length,
            itemBuilder: (context, index) => _JobPaymentRow(job: jobs[index]),
          ),
        );
      },
    );
  }
}

class _JobPaymentRow extends ConsumerStatefulWidget {
  const _JobPaymentRow({required this.job});

  final Job job;

  @override
  ConsumerState<_JobPaymentRow> createState() => _JobPaymentRowState();
}

class _JobPaymentRowState extends ConsumerState<_JobPaymentRow> {
  bool _isSubmitting = false;
  bool _justMarkedPaid = false;

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
      await ref.read(adminRepositoryProvider).markPaid(widget.job.id, transactionSlip: slipFile);
      if (mounted) {
        // The job list has no payment-status field to refresh against (see
        // class comment), so there's nothing to invalidate that would make
        // the button disappear on its own — track it locally instead.
        setState(() => _justMarkedPaid = true);
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
    final job = widget.job;
    return Card(
      child: ListTile(
        title: Text(formatDateTime(job.pickupDatetime)),
        subtitle: Text('${job.customerName} · ${job.pickupLocation} → ${job.dropoffLocation}'),
        trailing: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _justMarkedPaid
                ? const Chip(label: Text('Paid'))
                : FilledButton(
                    onPressed: _markPaid,
                    child: Text('Mark Paid  ${formatCurrency(job.fare)}'),
                  ),
      ),
    );
  }
}
