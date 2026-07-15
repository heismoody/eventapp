import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('d MMM yyyy, HH:mm').format(date.toLocal());
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('d MMM yyyy').format(date.toLocal());
  }

  static String formatTime(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('HH:mm').format(date.toLocal());
  }
}
