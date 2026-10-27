import 'package:intl/intl.dart';

import 'date_time_utils.dart';

class AppFormatters {
  const AppFormatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: 'PHP ',
    decimalDigits: 2,
  );

  static final NumberFormat _percent = NumberFormat('0.0');

  static String currency(double value) => _currency.format(value);

  static String signedCurrency(double value) {
    final sign = value >= 0 ? '+' : '-';
    return '$sign${currency(value.abs())}';
  }

  static String percentage(double value) => '${_percent.format(value)}%';

  static String date(String iso) => DateTimeUtils.dateLabel(iso);

  static String dateTime(String iso) => DateTimeUtils.dateTimeLabel(iso);

  /// Formats a person's name as "Juan Dela Cruz". Words typed in all
  /// lowercase or all caps are capitalized; mixed-case words such as
  /// "McArthur" are kept as typed.
  static String personName(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word.split('-').map(_capitalizeWord).join('-'))
        .join(' ');
  }

  static String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    final isUniformCase =
        word == word.toLowerCase() || word == word.toUpperCase();
    final rest = isUniformCase
        ? word.substring(1).toLowerCase()
        : word.substring(1);
    return word[0].toUpperCase() + rest;
  }
}
