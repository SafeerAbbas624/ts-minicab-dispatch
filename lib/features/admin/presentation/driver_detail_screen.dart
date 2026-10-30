import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/document_types.dart';
import '../../../core/models/admin_driver_detail.dart';
import '../../../core/models/driver.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/application/auth_controller.dart';
import '../../driver/presentation/profile_screen.dart';
import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import 'widgets/document_review_dialog.dart';

/// Thin Scaffold wrapper around [DriverDetailView] for the mobile
/// full-screen push (`Navigator.push` from driver_queue_screen.dart). Desktop
/// list screens embed [DriverDetailView] directly in a side pane instead,
/// which already supplies its own scroll wrapper — [DriverDetailView] itself
/// stays a plain (non-scrolling) Column so it isn't a scrollable nested
/// inside a scrollable in that case.
class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DriverDetailView(driverId: driverId),
      ),
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
        final vehicle = driver.vehicle;
        String orDash(String? v) => (v == null || v.isEmpty) ? '—' : v;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(driver.fullName, style: Theme.of(context).textTheme.titleLarge)),
                if (driver.callSign != null)
                  Chip(
                    avatar: const Icon(Icons.tag, size: 16),
                    label: Text(driver.callSign!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            Text(driver.email),
            Text(driver.phoneNumber),
            if (driver.compliance != null) ...[
              const SizedBox(height: 12),
              _ComplianceCard(compliance: driver.compliance!),
            ],
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
            Row(
              children: [
                Expanded(child: Text('Driver & vehicle details', style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: Text('Edit ${driver.fullName}')),
                        body: DriverDetailsForm(
                          driver: driver,
                          onSaveProfile: (changes) => repo.updateDriverProfile(widget.driverId, changes),
                          onSaveVehicle: (v) => repo.updateDriverVehicle(widget.driverId, v),
                        ),
                      ),
                    ));
                    _refresh();
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ),
            _InfoRow('Date of birth', driver.dateOfBirth == null ? '—' : formatDate(driver.dateOfBirth!)),
            _InfoRow('Address', [driver.addressLine, driver.postcode].whereType<String>().join(', ').ifEmpty('—')),
            _InfoRow('NI number', orDash(driver.niNumber)),
            _InfoRow('DVLA licence no.', orDash(driver.drivingLicenceNumber)),
            _InfoRow('TfL badge no.', orDash(driver.phvDriverLicenceNumber)),
            _InfoRow('Vehicle', vehicle == null ? '—' : orDash(vehicle.description)),
            _InfoRow('Registration', orDash(vehicle?.registration)),
            _InfoRow('PHV vehicle licence', orDash(vehicle?.phvLicenceNumber)),
            if (vehicle != null && !vehicle.ownedByDriver) const _InfoRow('Keeper', 'Not the driver — permission letter required'),
            if (driver.signedUpAt != null) _InfoRow('Signed up', formatDate(driver.signedUpAt!)),
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
    var subtitle = isRejected
        ? 'Rejected${document.rejectionReason != null && document.rejectionReason!.isNotEmpty ? ': ${document.rejectionReason}' : ''}'
        : (isVerified ? 'Verified' : 'Pending review');
    final days = document.daysUntilExpiry;
    if (document.expiryDate != null) {
      subtitle += ' · expires ${formatDate(document.expiryDate!)}';
      if (days != null && days <= 30) subtitle += days <= 0 ? ' (EXPIRED)' : ' ($days days left)';
    } else if (documentTypeExpires(document.type)) {
      subtitle += ' · no expiry date set';
    }
    final warn = (days != null && days <= 30) || (document.expiryDate == null && documentTypeExpires(document.type));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(documentTypeLabel(document.type)),
      subtitle: Text(subtitle, style: warn ? TextStyle(color: Theme.of(context).colorScheme.error) : null),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (documentTypeExpires(document.type))
            IconButton(
              tooltip: 'Set expiry date',
              icon: const Icon(Icons.event_outlined),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: document.expiryDate ?? now.add(const Duration(days: 365)),
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 15),
                  helpText: 'Expiry of ${documentTypeLabel(document.type)}',
                );
                if (picked == null) return;
                try {
                  await ref.read(adminRepositoryProvider).setDocumentExpiry(driverId, document.id, picked);
                  ref.invalidate(adminDriverDetailProvider(driverId));
                } on ApiException catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// What's stopping this driver being approved (or working), at a glance —
/// mirrors the server's own approval check.
class _ComplianceCard extends StatelessWidget {
  const _ComplianceCard({required this.compliance});

  final DriverCompliance compliance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = <String>[
      ...compliance.missingDetails.map((d) => 'Missing: $d'),
      ...compliance.missingDocuments.map((t) => 'Not uploaded: ${documentTypeLabel(t)}'),
      ...compliance.awaitingReview.map((t) => 'Awaiting your review: ${documentTypeLabel(t)}'),
      ...compliance.rejectedDocuments.map((t) => 'Rejected, needs re-upload: ${documentTypeLabel(t)}'),
      ...compliance.expired.map((e) => 'EXPIRED ${formatDate(e.expiryDate)}: ${documentTypeLabel(e.type)}'),
      ...compliance.expiringSoon.map((e) => 'Expires in ${e.daysLeft} days: ${documentTypeLabel(e.type)}'),
    ];
    final ok = compliance.compliant && !compliance.hasExpiringSoon;
    final bad = compliance.hasExpired || !compliance.compliant;
    final bg = ok ? colors.primaryContainer : (bad ? colors.errorContainer : colors.tertiaryContainer);
    final fg = ok ? colors.onPrimaryContainer : (bad ? colors.onErrorContainer : colors.onTertiaryContainer);
    return Card(
      color: bg,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ok ? Icons.verified : Icons.rule, color: fg),
                const SizedBox(width: 8),
                Text(
                  ok ? 'Compliant — all details and documents in date' : (compliance.compliant ? 'Compliant, renewals due' : 'Not compliant'),
                  style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 32),
                child: Text('• $item', style: TextStyle(color: fg)),
              ),
          ],
        ),
      ),
    );
  }
}
