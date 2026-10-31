import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_download_stub.dart' if (dart.library.js_interop) 'csv_download_web.dart';

/// Hands a downloaded CSV to the user: the share sheet on phones, a plain
/// file download (with the exact `.csv` name) in the web admin panel.
Future<void> shareCsv(List<int> bytes, String fileName, {String? subject}) =>
    shareFile(bytes, fileName, mimeType: 'text/csv;charset=utf-8', subject: subject);

/// Same for any generated file, e.g. a record PDF.
Future<void> shareFile(List<int> bytes, String fileName, {required String mimeType, String? subject}) async {
  if (kIsWeb) {
    downloadFile(bytes, fileName, mimeType);
    return;
  }
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$fileName');
  await f.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(f.path, mimeType: mimeType)], fileNameOverrides: [fileName], subject: subject ?? fileName),
  );
}
