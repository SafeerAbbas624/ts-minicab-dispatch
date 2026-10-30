import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'csv_download_stub.dart' if (dart.library.js_interop) 'csv_download_web.dart';

/// Hands a downloaded CSV to the user: the share sheet on phones, a plain
/// file download (with the exact `.csv` name) in the web admin panel.
Future<void> shareCsv(List<int> bytes, String fileName, {String? subject}) async {
  if (kIsWeb) {
    downloadCsv(bytes, fileName);
    return;
  }
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$fileName');
  await f.writeAsBytes(bytes);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(f.path, mimeType: 'text/csv')], fileNameOverrides: [fileName], subject: subject ?? fileName),
  );
}
