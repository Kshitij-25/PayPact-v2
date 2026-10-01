import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

enum ExportOutcome { shared, copied }

/// Hands a generated text file to the user: the system share sheet (save to
/// Files, email, AirDrop…), or — where files can't be shared, e.g. some
/// desktop browsers — the contents on the clipboard.
Future<ExportOutcome> shareTextFile({
  required String fileName,
  required String mimeType,
  required String content,
  String? subject,
}) async {
  try {
    final result = await SharePlus.instance.share(ShareParams(
      files: [
        XFile.fromData(Uint8List.fromList(utf8.encode(content)),
            mimeType: mimeType, name: fileName),
      ],
      fileNameOverrides: [fileName],
      subject: subject,
    ));
    if (result.status != ShareResultStatus.unavailable) {
      return ExportOutcome.shared;
    }
  } catch (_) {}
  await Clipboard.setData(ClipboardData(text: content));
  return ExportOutcome.copied;
}
