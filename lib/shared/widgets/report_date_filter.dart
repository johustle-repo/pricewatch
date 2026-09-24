import 'package:flutter/material.dart';
import '../../core/utils/app_formatters.dart';

bool matchesReportDate(String timestamp, DateTime? selected) {
  if (selected == null) return true;
  final date = DateTime.tryParse(timestamp)?.toLocal();
  return date != null && DateUtils.isSameDay(date, selected);
}

class ReportDateFilter extends StatelessWidget {
  const ReportDateFilter({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month),
        label: Text(
          value == null
              ? 'Report date: All dates'
              : 'Report date: ${AppFormatters.date(value!.toIso8601String())}',
        ),
        onPressed: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2100, 12, 31),
            helpText: 'Select report submission date',
          );
          if (context.mounted && selected != null) onChanged(selected);
        },
      ),
      if (value != null)
        TextButton(
          onPressed: () => onChanged(null),
          child: const Text('Clear date'),
        ),
    ],
  );
}
