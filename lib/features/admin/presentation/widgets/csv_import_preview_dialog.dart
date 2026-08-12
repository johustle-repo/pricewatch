import 'package:flutter/material.dart';

import '../../data/csv_import_service.dart';

class CsvImportDecision {
  const CsvImportDecision(this.strategy);
  final CsvDuplicateStrategy strategy;
}

Future<CsvImportDecision?> showCsvImportPreview({
  required BuildContext context,
  required String title,
  required List<Map<String, String>> rows,
}) {
  var strategy = CsvDuplicateStrategy.update;
  final headers = rows.isEmpty ? <String>[] : rows.first.keys.toList();
  return showDialog<CsvImportDecision>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        title: Text(title),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 760,
            maxHeight: MediaQuery.sizeOf(context).height * 0.68,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rows.length} data row(s) detected. Review the sample before importing.',
                ),
                const SizedBox(height: 14),
                if (headers.isNotEmpty)
                  Container(
                    height: 280,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        primary: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 44,
                            dataRowMinHeight: 42,
                            dataRowMaxHeight: 54,
                            columns: headers
                                .map(
                                  (header) => DataColumn(
                                    label: Text(
                                      header,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            rows: rows
                                .take(8)
                                .map(
                                  (row) => DataRow(
                                    cells: headers
                                        .map(
                                          (header) => DataCell(
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                minWidth: 120,
                                                maxWidth: 190,
                                              ),
                                              child: Text(
                                                row[header] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  'When a matching record already exists',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                RadioGroup<CsvDuplicateStrategy>(
                  groupValue: strategy,
                  onChanged: (value) => setState(() => strategy = value!),
                  child: const Column(
                    children: [
                      RadioListTile(
                        value: CsvDuplicateStrategy.skip,
                        title: Text('Skip duplicates'),
                        subtitle: Text('Keep existing records unchanged.'),
                      ),
                      RadioListTile(
                        value: CsvDuplicateStrategy.update,
                        title: Text('Update duplicates'),
                        subtitle: Text('Update the matching current record.'),
                      ),
                      RadioListTile(
                        value: CsvDuplicateStrategy.replace,
                        title: Text('Replace duplicates'),
                        subtitle: Text(
                          'Replace matching data with CSV values.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All rows are validated before any valid record is saved. Invalid rows are skipped and included in an error report.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: rows.isEmpty
                ? null
                : () => Navigator.of(context).pop(CsvImportDecision(strategy)),
            icon: const Icon(Icons.upload_rounded),
            label: const Text('Validate and import'),
          ),
        ],
      ),
    ),
  );
}
