// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class CsvFilePicker {
  const CsvFilePicker._();

  static Future<Uint8List?> pickBytes() {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()
      ..accept = '.csv,text/csv'
      ..multiple = false;
    input.onChange.first.then((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onError.first.then((_) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('The selected CSV could not be read.'),
          );
        }
      });
      reader.onLoad.first.then((_) {
        final result = reader.result;
        if (result is ByteBuffer) {
          completer.complete(result.asUint8List());
        } else if (result is Uint8List) {
          completer.complete(result);
        } else {
          completer.completeError(
            Exception('The selected CSV has an unsupported format.'),
          );
        }
      });
      reader.readAsArrayBuffer(files.first);
    });
    input.click();
    return completer.future;
  }
}
