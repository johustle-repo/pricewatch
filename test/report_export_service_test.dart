import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/features/admin/data/report_export_service.dart';
import 'package:pricewatch_apk/shared/models/ui_models.dart';

void main() {
  const report = ReportViewData(
    reportId: 1,
    commodityName: 'Bangus',
    storeName: 'Lingayen Public Market',
    userName: 'Community User',
    observedPrice: 260,
    srpSnapshot: 240,
    reason: 'Price was higher than the posted SRP.',
    photoPath: null,
    status: 'pending',
    createdAt: '2026-08-09T08:00:00.000Z',
    updatedAt: '2026-08-09T08:00:00.000Z',
  );

  test('CSV export is UTF-8 BOM encoded and Excel compatible', () {
    final bytes = ReportExportService.buildCsvBytes([report]);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final content = utf8.decode(bytes.skip(3).toList());
    expect(content, contains('Lingayen Public Market'));
    expect(content, contains('20.00'));
  });

  test('PDF export produces a valid PDF document', () async {
    final bytes = await ReportExportService.buildPdfBytes([report]);
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });
}
