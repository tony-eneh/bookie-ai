import 'package:intl/intl.dart';

abstract final class DateFormatter {
  static String relative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.isNegative) return fullDate(date);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';

    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final dayDiff = today.difference(dateDay).inDays;

    if (dayDiff == 1) return 'yesterday';
    if (dayDiff < 7) return '${dayDiff}d ago';
    if (dayDiff < 30) return '${(dayDiff / 7).floor()}w ago';

    return fullDate(date);
  }

  static String fullDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  static String shortDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM y').format(date);
  }

  static String shortMonthYear(DateTime date) {
    return DateFormat('MMM y').format(date);
  }

  static String time(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String dateTime(DateTime date) {
    return DateFormat('MMM d, y · h:mm a').format(date);
  }

  static String dayOfWeek(DateTime date) {
    return DateFormat('EEEE').format(date);
  }
}
