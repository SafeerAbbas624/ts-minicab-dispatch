import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'upload_validation.dart';

enum _UploadSource { camera, photos, files }

/// Lets the user choose where an upload comes from, the way iOS and Android
/// apps normally do: a photo from the camera or the photo library, or a
/// document (PDF/image) from Files. Photos go through image_picker, which
/// hands back a JPEG — iPhone photos are HEIC otherwise, which the backend
/// (and admins' browsers) can't use. Returns null if the user cancels.
Future<File?> pickUploadFile(BuildContext context, {bool photosOnly = false, String? title}) async {
  final source = await showModalBottomSheet<_UploadSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.of(context).pop(_UploadSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Photo library'),
            onTap: () => Navigator.of(context).pop(_UploadSource.photos),
          ),
          if (!photosOnly)
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Files'),
              subtitle: const Text('PDF or image'),
              onTap: () => Navigator.of(context).pop(_UploadSource.files),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  switch (source) {
    case _UploadSource.camera:
    case _UploadSource.photos:
      final image = await ImagePicker().pickImage(
        source: source == _UploadSource.camera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      return image == null ? null : File(image.path);
    case _UploadSource.files:
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: allowedUploadExtensions);
      return file?.path == null ? null : File(file!.path!);
  }
}
