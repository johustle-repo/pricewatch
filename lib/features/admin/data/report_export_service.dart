import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/models/ui_models.dart';

class ReportExportService {
  const ReportExportService._();

  static Future<void> saveCsv(List<ReportViewData> reports) async {
    final bytes = buildCsvBytes(reports);
    await FileSaver.instance.saveFile(
      name: _fileName('csv'),
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static Uint8List buildCsvBytes(List<ReportViewData> reports) {
    final rows = <List<Object?>>[
      [
        'Report ID',
        'Reporter',
        'Store',
        'Commodity',
        'Observed Price',
        'SRP',
        'Variance',
        'Reason',
        'Status',
        'Submitted',
      ],
      ...reports.map(
        (report) => [
          report.reportId,
          report.userName,
          report.storeName,
          report.commodityName,
          report.observedPrice.toStringAsFixed(2),
          report.srpSnapshot.toStringAsFixed(2),
          (report.observedPrice - report.srpSnapshot).toStringAsFixed(2),
          report.reason,
          report.status,
          report.createdAt,
        ],
      ),
    ];
    final content = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    return Uint8List.fromList(utf8.encode('\ufeff$content'));
  }

  static Future<void> savePdf(List<ReportViewData> reports) async {
    final bytes = await buildPdfBytes(reports);
    await FileSaver.instance.saveFile(
      name: _fileName('pdf'),
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<Uint8List> buildPdfBytes(List<ReportViewData> reports) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PriceWatch Community Report Register',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated ${DateFormat('MMMM d, y h:mm a').format(DateTime.now())} - ${reports.length} record(s)',
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 8,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF164E3D),
            ),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellPadding: const pw.EdgeInsets.all(5),
            headers: const [
              'ID',
              'Reporter',
              'Store',
              'Commodity',
              'Observed',
              'SRP',
              'Variance',
              'Status',
              'Submitted',
            ],
            data: reports
                .map(
                  (report) => [
                    report.reportId,
                    report.userName,
                    report.storeName,
                    report.commodityName,
                    report.observedPrice.toStringAsFixed(2),
                    report.srpSnapshot.toStringAsFixed(2),
                    (report.observedPrice - report.srpSnapshot).toStringAsFixed(
                      2,
                    ),
                    report.status.toUpperCase(),
                    DateFormat(
                      'MMM d, y',
                    ).format(DateTime.parse(report.createdAt).toLocal()),
                  ],
                )
                .toList(),
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
    return document.save();
  }

  static String _csvCell(Object? value) =>
      '"${value.toString().replaceAll('"', '""')}"';

  static String _fileName(String extension) =>
      'pricewatch_reports_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
}
