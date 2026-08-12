import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminExportService {
  const AdminExportService._();

  static Future<void> savePdf({
    required String title,
    required String filePrefix,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(26),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated ${DateFormat('MMMM d, y h:mm a').format(DateTime.now())} | ${rows.length} record(s)',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF17233B),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 7,
            ),
            cellStyle: const pw.TextStyle(fontSize: 6.5),
            cellPadding: const pw.EdgeInsets.all(4),
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ),
    );
    await FileSaver.instance.saveFile(
      name: _fileName(filePrefix),
      bytes: await document.save(),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<void> saveXlsx({
    required String sheetName,
    required String filePrefix,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    if (defaultSheet != null && defaultSheet != sheetName) {
      workbook.rename(defaultSheet, sheetName);
    }
    final sheet = workbook[sheetName];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (final row in rows) {
      sheet.appendRow(row.map(_cellValue).toList());
    }
    for (var index = 0; index < headers.length; index++) {
      sheet.setColumnAutoFit(index);
    }
    final encoded = workbook.encode();
    if (encoded == null) throw Exception('Excel file could not be generated.');
    await FileSaver.instance.saveFile(
      name: _fileName(filePrefix),
      bytes: Uint8List.fromList(encoded),
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static CellValue _cellValue(Object? value) {
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    if (value is bool) return BoolCellValue(value);
    return TextCellValue(value?.toString() ?? '');
  }

  static String _fileName(String prefix) =>
      '${prefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
}
