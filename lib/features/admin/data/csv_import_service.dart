import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';

enum CsvDuplicateStrategy { skip, update, replace }

class CsvImportService {
  const CsvImportService._();

  static List<Map<String, String>> parse(Uint8List bytes) {
    final text = utf8
        .decode(bytes, allowMalformed: false)
        .replaceFirst('\ufeff', '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(text);
    if (rows.isEmpty) throw const FormatException('The CSV file is empty.');

    final headers = rows.first
        .map((value) => _normalize(value.toString()))
        .toList();
    if (headers.any((value) => value.isEmpty)) {
      throw const FormatException('CSV headers cannot be empty.');
    }

    return rows
        .skip(1)
        .where((row) => row.any((value) => value.toString().trim().isNotEmpty))
        .map((row) {
          return <String, String>{
            for (var index = 0; index < headers.length; index++)
              headers[index]: index < row.length
                  ? row[index].toString().trim()
                  : '',
          };
        })
        .toList();
  }

  static String value(Map<String, String> row, List<String> aliases) {
    for (final alias in aliases) {
      final result = row[_normalize(alias)];
      if (result != null && result.trim().isNotEmpty) return result.trim();
    }
    return '';
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static Future<void> saveErrorReport(
    List<String> errors, {
    required String filePrefix,
  }) async {
    final bytes = buildErrorReportBytes(errors);
    await FileSaver.instance.saveFile(
      name: '${filePrefix}_errors',
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static Uint8List buildErrorReportBytes(List<String> errors) {
    final rows = <List<Object?>>[
      ['Import Error'],
      ...errors.map((error) => [error]),
    ];
    final content = const ListToCsvConverter().convert(rows);
    return Uint8List.fromList(utf8.encode('\ufeff$content'));
  }
}

class CsvImportResult {
  const CsvImportResult({
    required this.imported,
    required this.skipped,
    required this.errors,
  });

  final int imported;
  final int skipped;
  final List<String> errors;

  String get summary => '$imported imported, $skipped skipped';
}
