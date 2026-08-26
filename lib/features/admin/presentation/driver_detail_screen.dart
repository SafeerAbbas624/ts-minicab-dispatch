import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/document_types.dart';
import '../../../core/models/admin_driver_detail.dart';
import '../../../core/models/driver.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/application/auth_controller.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import 'widgets/document_review_dialog.dart';

/// Thin Scaffold wrapper around [DriverDetailView] for the mobile
/// full-screen push (`Navigator.push` from driver_queue_screen.dart). Desktop
/// list screens embed [DriverDetailView] directly in a side pane instead.
class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver')),
      body: DriverDetailView(driverId: driverId),
    );
  }
}

class DriverDetailView extends ConsumerStatefulWidget {
  const DriverDetailView({super.key, required this.driverId});

  final String driverId;

  @override
  ConsumerState<DriverDetailView> createState() => _DriverDetailViewState();
}

class _DriverDetailViewState extends ConsumerState<DriverDetailView> {
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(adminDriverDetailProvider(widget.driverId));
    ref.invalidate(adminDriversProvider);
  }

  Future<void> _runAction(Future<void> Function() action, {String? successMessage}) async {
    setState(() => _isSubmitting = true);
    try {
      await action();
      _refresh();
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this driver?'),
        content: const Text('This permanently removes the driver account. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repo = ref.read(adminRepositoryProvider);
    await _runAction(() => repo.deleteDriver(widget.driverId));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    final repo = ref.read(adminRepositoryProvider);
    await _runAction(() => repo.addDriverNote(widget.driverId, text));
    _noteController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminDriverDetailProvider(widget.driverId));
    final isSuperAdmin = ref.watch(authControllerProvider).role?.isSuperAdmin ?? false;
    final repo = ref.read(adminRepositoryProvider);

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(error.toString())),
      data: (detail) {
        final driver = detail.driver;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(driver.fullName, style: Theme.of(context).textTheme.titleLarge),
            Text(driver.email),
            Text(driver.phoneNumber),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _runAction(
                            () => repo.approveDriver(widget.driverId),
                            successMessage: 'Driver approved',
                          ),
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _runAction(
                            () => repo.rejectDriver(widget.driverId),
                            successMessage: 'Driver rejected',
                          ),
                  child: const Text('Reject'),
                ),
                OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => _runAction(
                            () => repo.suspendDriver(widget.driverId),
                            successMessage: 'Driver suspended',
                          ),
                  child: const Text('Suspend'),
                ),
                if (isSuperAdmin)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: _isSubmitting ? null : _confirmDelete,
                    child: const Text('Delete'),
                  ),
              ],
            ),
            const Divider(height: 32),
            Text('Documents', style: Theme.of(context).textTheme.titleMedium),
            if (detail.documents.isEmpty) const Text('No documents uploaded'),
            ...detail.documents.map(
              (doc) => _AdminDocumentTile(driverId: widget.driverId, document: doc),
            ),
            const Divider(height: 32),
            Text('Bank Details', style: Theme.of(context).textTheme.titleMedium),
            _BankDetailsView(bankDetails: detail.bankDetails),
            const Divider(height: 32),
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            ...detail.notes.map(
              (note) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(note.text),
                subtitle: Text(note.authorName ?? ''),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(hintText: 'Add a note'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _addNote),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AdminDocumentTile extends ConsumerWidget {
  const _AdminDocumentTile({required this.driverId, required this.document});

  final String driverId;
  final DriverDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRejected = document.reviewStatus == 'rejected';
    final isVerified = document.isVerified;
    final subtitle = isRejected
        ? 'Rejected${document.rejectionReason != null && document.rejectionReason!.isNotEmpty ? ': ${document.rejectionReason}' : ''}'
        : (isVerified ? 'Verified' : 'Pending review');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(documentTypeLabel(document.type)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDocumentReviewDialog(
        context,
        ref,
        driverId: driverId,
        document: document,
        onReviewed: () => ref.invalidate(adminDriverDetailProvider(driverId)),
      ),
    );
  }
}

class _BankDetailsView extends StatelessWidget {
  const _BankDetailsView({required this.bankDetails});

  final BankDetails bankDetails;

  @override
  Widget build(BuildContext context) {
    if (!bankDetails.hasAny) {
      return const Text('No bank details on file');
    }
    return Text(bankDetails.raw!);
  }
}
