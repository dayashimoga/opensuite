import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<void> saveOrDownloadFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    bytes: bytes,
  );
  if (path != null) {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }
}
