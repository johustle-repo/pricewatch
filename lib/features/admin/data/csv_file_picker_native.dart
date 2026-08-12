import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class CsvFilePicker {
  const CsvFilePicker._();

  static Future<Uint8List?> pickBytes() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (picked == null) return null;
    final selected = picked.files.single;
    if (selected.bytes != null) return selected.bytes;
    final path = selected.path;
    return path == null ? null : File(path).readAsBytes();
  }
}
