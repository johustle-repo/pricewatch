import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pricewatch_apk/features/admin/data/csv_import_service.dart';

void main() {
  test('parses price-list and store-name CSV headers', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        'Commodity,PriceList,StoreName\r\nBangus,245.50,Lingayen Public Market',
      ),
    );
    final rows = CsvImportService.parse(bytes);
    expect(rows, hasLength(1));
    expect(CsvImportService.value(rows.first, ['PriceList']), '245.50');
    expect(
      CsvImportService.value(rows.first, ['StoreName']),
      'Lingayen Public Market',
    );
  });

  test('preserves quoted commas in store CSV values', () {
    final bytes = Uint8List.fromList(
      utf8.encode(
        'StoreName,MarketName,Address,City\n"Market Stall 1","Lingayen Market","Aguinaldo St., Poblacion",Lingayen',
      ),
    );
    final rows = CsvImportService.parse(bytes);
    expect(
      CsvImportService.value(rows.first, ['Address']),
      'Aguinaldo St., Poblacion',
    );
  });

  test('builds a downloadable CSV error report', () {
    final bytes = CsvImportService.buildErrorReportBytes([
      'Row 2: unknown store.',
      'Duplicate skipped: Bangus at Sample Stall 01.',
    ]);
    final content = utf8.decode(bytes).replaceFirst('\ufeff', '');
    expect(content, contains('Import Error'));
    expect(content, contains('Row 2: unknown store.'));
    expect(content, contains('Duplicate skipped'));
  });
}
