import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/document_types.dart';
import '../../../core/models/driver.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/upload_validation.dart';
import '../application/driver_providers.dart';
import '../data/driver_repository.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(driverDocumentsProvider);
    final me = ref.watch(driverMeProvider).valueOrNull;
    // The permission letter only applies when the driver isn't the vehicle's
    // registered keeper.
    final needsPermissionLetter = me?.vehicle != null && me!.vehicle!.ownedByDriver == false;
    final required = [...requiredDocumentTypes, if (needsPermissionLetter) 'permission_letter'];

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (documents) {
          // Newest upload per type wins — older ones are superseded.
          final sorted = [...documents]
            ..sort((a, b) => (b.uploadedAt ?? DateTime(0)).compareTo(a.uploadedAt ?? DateTime(0)));
          final byType = <String, DriverDocument>{};
          for (final d in sorted) {
            byType.putIfAbsent(d.type, () => d);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(driverDocumentsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (me?.compliance != null) _ComplianceSummary(compliance: me!.compliance!),
                const _SectionTitle('Required'),
                for (final type in required) _DocumentTile(type: type, document: byType[type]),
                const SizedBox(height: 8),
                const _SectionTitle('Optional'),
                for (final type in optionalDocumentTypes) _DocumentTile(type: type, document: byType[type]),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      );
}

class _ComplianceSummary extends StatelessWidget {
  const _ComplianceSummary({required this.compliance});
  final DriverCompliance compliance;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (icon, color, bg, title) = compliance.hasExpired
        ? (Icons.error, colors.onErrorContainer, colors.errorContainer, 'A document has expired — you can\'t take jobs until it\'s replaced')
        : compliance.hasExpiringSoon
            ? (Icons.schedule, colors.onTertiaryContainer, colors.tertiaryContainer, 'A document expires soon — upload the renewal')
            : compliance.compliant
                ? (Icons.verified, colors.onPrimaryContainer, colors.primaryContainer, 'All documents verified and in date')
                : (Icons.pending_actions, colors.onSecondaryContainer, colors.secondaryContainer, 'Some documents still need uploading or review');
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends ConsumerStatefulWidget {
  const _DocumentTile({required this.type, this.document});

  final String type;
  final DriverDocument? document;

  @override
  ConsumerState<_DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends ConsumerState<_DocumentTile> {
  bool _isUploading = false;

  Future<DateTime?> _askExpiry() {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 15),
      helpText: 'Expiry date of this ${documentTypeLabel(widget.type)}',
    );
  }

  Future<void> _pickAndUpload() async {
    DateTime? expiry;
    if (documentTypeExpires(widget.type)) {
      expiry = await _askExpiry();
      if (expiry == null) return;
    }

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedUploadExtensions,
    );
    if (file == null || file.path == null) return;

    final picked = File(file.path!);
    final validationError = await validateUploadFile(picked);
    if (validationError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError)));
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      await ref.read(driverRepositoryProvider).uploadDocument(
            documentType: widget.type,
            file: picked,
            expiryDate: expiry,
          );
      ref.invalidate(driverDocumentsProvider);
      ref.invalidate(driverMeProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final document = widget.document;
    final isVerified = document?.isVerified ?? false;
    final isRejected = document?.reviewStatus == 'rejected';
    final days = document?.daysUntilExpiry;
    final expired = days != null && days <= 0;

    String subtitle;
    if (document == null) {
      subtitle = 'Not uploaded';
    } else if (isRejected) {
      subtitle = document.rejectionReason == null || document.rejectionReason!.isEmpty
          ? 'Rejected — please re-upload'
          : 'Rejected: ${document.rejectionReason}';
    } else if (isVerified) {
      subtitle = 'Verified';
    } else {
      subtitle = 'Pending review';
    }
    if (document?.expiryDate != null) subtitle += ' · expires ${formatDate(document!.expiryDate!)}';

    final (IconData icon, Color? color) = document == null
        ? (Icons.upload_file, null)
        : expired || isRejected
            ? (Icons.cancel, colors.error)
            : isVerified
                ? (Icons.check_circle, Colors.green)
                : (Icons.hourglass_top, Colors.orange);

    return Card(
      child: ListTile(
        title: Text(documentTypeLabel(widget.type)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (days != null && days <= 30)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _ExpiryChip(days: days),
              ),
          ],
        ),
        leading: Icon(icon, color: color),
        trailing: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _pickAndUpload,
                child: Text(document == null ? 'Upload' : (days != null && days <= 30 ? 'Renew' : 'Replace')),
              ),
      ),
    );
  }
}

/// "Expires in 12 days" / "Expired" — red within 7 days, amber within 30.
class _ExpiryChip extends StatelessWidget {
  const _ExpiryChip({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final urgent = days <= 7;
    final label = days <= 0 ? 'Expired' : 'Expires in $days day${days == 1 ? '' : 's'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? colors.errorContainer : colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: urgent ? colors.onErrorContainer : colors.onTertiaryContainer,
        ),
      ),
    );
  }
}
