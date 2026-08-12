import 'package:intl/intl.dart';

class DateTimeUtils {
  const DateTimeUtils._();

  static String nowIso() => DateTime.now().toUtc().toIso8601String();

  static DateTime parseIso(String iso) => DateTime.parse(iso).toLocal();

  static String dateLabel(String iso) {
    return DateFormat('MMM d, y').format(parseIso(iso));
  }

  static String dateTimeLabel(String iso) {
    return DateFormat('MMM d, y | h:mm a').format(parseIso(iso));
  }
}
