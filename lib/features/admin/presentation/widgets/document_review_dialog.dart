import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/document_types.dart';
import '../../../../core/models/driver.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/admin_repository.dart';

bool _looksLikePdf(Uint8List bytes) =>
    bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46;

/// Fetches and shows a driver-uploaded document's file, with Verify/Reject
/// actions for a still-pending document. Images render inline
/// (pinch-zoomable); PDFs get saved to a temp file and handed off to the
/// device's own viewer via share_plus, since there's no in-app PDF renderer.
Future<void> showDocumentReviewDialog(
  BuildContext context,
  WidgetRef ref, {
  required String driverId,
  required DriverDocument document,
  required VoidCallback onReviewed,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _DocumentReviewDialog(
      driverId: driverId,
      document: document,
      onReviewed: onReviewed,
    ),
  );
}

class _DocumentReviewDialog extends ConsumerStatefulWidget {
  const _DocumentReviewDialog({
    required this.driverId,
    required this.document,
    required this.onReviewed,
  });

  final String driverId;
  final DriverDocument document;
  final VoidCallback onReviewed;

  @override
  ConsumerState<_DocumentReviewDialog> createState() => _DocumentReviewDialogState();
}

class _DocumentReviewDialogState extends ConsumerState<_DocumentReviewDialog> {
  Uint8List? _bytes;
  String? _loadError;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await ref
          .read(adminRepositoryProvider)
          .fetchDocumentFile(widget.driverId, widget.document.id);
      if (mounted) setState(() => _bytes = Uint8List.fromList(bytes));
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _openPdf(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${widget.document.id}.pdf');
    await file.writeAsBytes(bytes);
    if (!mounted) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: documentTypeLabel(widget.document.type)),
    );
  }

  Future<void> _verify() async {
    setState(() => _isBusy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .verifyDocument(widget.driverId, widget.document.id);
      widget.onReviewed();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject document'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason'),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .rejectDocument(widget.driverId, widget.document.id, reason);
      widget.onReviewed();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final isPending = document.reviewStatus != 'verified' && document.reviewStatus != 'rejected';

    return AlertDialog(
      title: Text(documentTypeLabel(document.type)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _buildPreview(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (isPending) ...[
          OutlinedButton(
            onPressed: _isBusy ? null : _reject,
            style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: _isBusy ? null : _verify,
            child: const Text('Verify'),
          ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    if (_loadError != null) {
      return Center(child: Text(_loadError!));
    }
    final bytes = _bytes;
    if (bytes == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_looksLikePdf(bytes)) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => _openPdf(bytes),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Open PDF'),
        ),
      );
    }
    return InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain));
  }
}
