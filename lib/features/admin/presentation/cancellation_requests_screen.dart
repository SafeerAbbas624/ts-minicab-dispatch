import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/job.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/responsive_master_detail_list.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';

/// Admin inbox for driver cancellation requests submitted within 2 hours of
/// pickup — see docs/BACKEND_REQUESTS.md #5. Only shows pending requests;
/// approved/rejected ones no longer need admin attention.
class CancellationRequestsScreen extends ConsumerWidget {
  const CancellationRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(adminCancellationRequestsProvider);

    return requestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (allRequests) {
        final requests = allRequests.where((r) => r.status == 'pending').toList();
        if (requests.isEmpty) {
          return const Center(child: Text('No pending cancellation requests'));
        }
        final mobileList = RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminCancellationRequestsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: requests.length,
            itemBuilder: (context, index) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _RequestContent(request: requests[index]),
              ),
            ),
          ),
        );
        return ResponsiveMasterDetailList<CancellationRequest>(
          items: requests,
          itemKey: (r) => r.id,
          mobileList: mobileList,
          // Row selection is new on desktop — the mobile card was never
          // tappable (only its two buttons did anything), purely additive.
          detailFor: (r) => _RequestContent(request: r),
          columns: const [
            DataColumn(label: Text('Requested')),
            DataColumn(label: Text('Driver')),
            DataColumn(label: Text('Route')),
            DataColumn(label: Text('Reason')),
            DataColumn(label: Text('Actions')),
          ],
          cellsFor: (r) => [
            DataCell(Text(formatDateTime(r.createdAt))),
            DataCell(Text(r.driver?.fullName ?? '—')),
            DataCell(Text(r.job != null ? '${r.job!.pickupLocation} → ${r.job!.dropoffLocation}' : '—')),
            DataCell(ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(r.reason, overflow: TextOverflow.ellipsis),
            )),
            DataCell(_RequestActions(request: r)),
          ],
        );
      },
    );
  }
}

/// Full content for one cancellation request — requested date, driver, job
/// route/pickup, reason, and the Approve/Reject actions. Used both as the
/// mobile card's body and as the desktop detail pane's content.
class _RequestContent extends StatelessWidget {
  const _RequestContent({required this.request});

  final CancellationRequest request;

  @override
  Widget build(BuildContext context) {
    final job = request.job;
    final driver = request.driver;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Requested ${formatDateTime(request.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        if (driver != null) Text(driver.fullName, style: Theme.of(context).textTheme.titleSmall),
        if (job != null) ...[
          Text('${job.pickupLocation} → ${job.dropoffLocation}'),
          Text('Pickup: ${formatDateTime(job.pickupDatetime)}'),
        ],
        const SizedBox(height: 8),
        Text('Reason: ${request.reason}'),
        const SizedBox(height: 12),
        _RequestActions(request: request),
      ],
    );
  }
}

/// Approve/Reject buttons for a cancellation request — shared between the
/// mobile/desktop card content and the desktop table's Actions column.
class _RequestActions extends ConsumerStatefulWidget {
  const _RequestActions({required this.request});

  final CancellationRequest request;

  @override
  ConsumerState<_RequestActions> createState() => _RequestActionsState();
}

class _RequestActionsState extends ConsumerState<_RequestActions> {
  bool _isSubmitting = false;

  Future<void> _approve() async {
    final penalize = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve cancellation'),
        content: const Text(
          "This releases the job back to the pool. If the driver's reason doesn't hold "
          'up, you can log a penalty note on their record at the same time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Approve, no penalty'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve + penalize'),
          ),
        ],
      ),
    );
    if (penalize == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .approveCancellationRequest(widget.request.id, penalize: penalize);
      ref.invalidate(adminCancellationRequestsProvider);
      ref.invalidate(adminJobsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cancellation approved, job released')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reject() async {
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject cancellation request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The job stays assigned to the driver — nothing changes.'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
              autofocus: true,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(noteController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (note == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .rejectCancellationRequest(widget.request.id, note: note.isEmpty ? null : note);
      ref.invalidate(adminCancellationRequestsProvider);
      ref.invalidate(adminJobsProvider(null));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cancellation request rejected')));
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
    return Wrap(
      spacing: 8,
      children: [
        TextButton(
          onPressed: _isSubmitting ? null : _reject,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Reject'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _approve,
          child: const Text('Approve'),
        ),
      ],
    );
  }
}
