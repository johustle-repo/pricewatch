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
}
