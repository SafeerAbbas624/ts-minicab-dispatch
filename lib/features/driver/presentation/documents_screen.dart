import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/driver.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/upload_validation.dart';
import '../application/driver_providers.dart';
import '../data/driver_repository.dart';

const _requiredDocumentTypes = [
  ('phv_licence', 'PHV Licence'),
  ('insurance', 'Insurance'),
  ('dbs', 'DBS Check'),
];

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(driverDocumentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: documentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
        data: (documents) {
          final byType = {for (final d in documents) d.type: d};
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _requiredDocumentTypes.length,
            itemBuilder: (context, index) {
              final (type, label) = _requiredDocumentTypes[index];
              return _DocumentTile(type: type, label: label, document: byType[type]);
            },
          );
        },
      ),
    );
  }
}

class _DocumentTile extends ConsumerStatefulWidget {
  const _DocumentTile({required this.type, required this.label, this.document});

  final String type;
  final String label;
  final DriverDocument? document;

  @override
  ConsumerState<_DocumentTile> createState() => _DocumentTileState();
}

class _DocumentTileState extends ConsumerState<_DocumentTile> {
  bool _isUploading = false;

  Future<void> _pickAndUpload() async {
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
          );
      ref.invalidate(driverDocumentsProvider);
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
    final document = widget.document;
    final isVerified = document?.isVerified ?? false;

    return Card(
      child: ListTile(
        title: Text(widget.label),
        subtitle: Text(
          document == null ? 'Not uploaded' : (isVerified ? 'Verified' : 'Pending review'),
        ),
        leading: Icon(
          document == null
              ? Icons.upload_file
              : (isVerified ? Icons.check_circle : Icons.hourglass_top),
          color: document == null
              ? null
              : (isVerified ? Colors.green : Colors.orange),
        ),
        trailing: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _pickAndUpload,
                child: Text(document == null ? 'Upload' : 'Replace'),
              ),
      ),
    );
  }
}
