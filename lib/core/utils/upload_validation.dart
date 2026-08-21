import 'dart:io';

const allowedUploadExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
const maxUploadSizeBytes = 10 * 1024 * 1024; // backend rejects anything larger with a 400

/// Returns null if [file] passes the backend's upload constraints (type,
/// size), or a user-facing error message if it doesn't — checked client-side
/// so the user gets immediate feedback instead of a round trip to a 400.
Future<String?> validateUploadFile(File file) async {
  final extension = file.path.split('.').last.toLowerCase();
  if (!allowedUploadExtensions.contains(extension)) {
    return 'Unsupported file type. Use PDF, JPEG, PNG, or WEBP.';
  }
  final size = await file.length();
  if (size > maxUploadSizeBytes) {
    return 'File is too large. Maximum size is 10MB.';
  }
  return null;
}
