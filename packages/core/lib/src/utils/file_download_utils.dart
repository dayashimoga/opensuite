import 'dart:typed_data';

import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    if (dart.library.io) 'file_download_io.dart';

/// Cross-platform utility for triggering immediate local file downloads
/// (e.g. browser download dialog on Web or native save file picker on Desktop/Mobile).
class FileDownloadUtils {
  FileDownloadUtils._();

  /// Triggers a local disk download/save of [bytes] with [fileName] and [mimeType].
  static Future<void> downloadBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    await saveOrDownloadFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
