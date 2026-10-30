import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a downloaded CSV to the user: the share sheet on phones, a file
/// download in the web admin panel (share_plus falls back to a download
/// where the browser can't share files — path_provider has no temp
/// directory on web, so the bytes are shared directly there).
Future<void> shareCsv(List<int> bytes, String fileName, {String? subject}) async {
  final XFile file;
  if (kIsWeb) {
    file = XFile.fromData(Uint8List.fromList(bytes), name: fileName, mimeType: 'text/csv');
  } else {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$fileName');
    await f.writeAsBytes(bytes);
    file = XFile(f.path, mimeType: 'text/csv');
  }
  await SharePlus.instance.share(ShareParams(files: [file], fileNameOverrides: [fileName], subject: subject ?? fileName));
}
