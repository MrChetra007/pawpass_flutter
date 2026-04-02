import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM d, yyyy • h:mm a');

  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  static String formatFullDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  static String formatAge(DateTime birthDate) {
    final now = DateTime.now();
    final years = now.year - birthDate.year;
    final months = now.month - birthDate.month;

    int totalMonths = years * 12 + months;
    if (now.day < birthDate.day) {
      totalMonths--;
    }

    if (totalMonths < 1) {
      final days = now.difference(birthDate).inDays;
      return '$days day${days == 1 ? '' : 's'}';
    } else if (totalMonths < 12) {
      return '$totalMonths month${totalMonths == 1 ? '' : 's'}';
    } else {
      final y = totalMonths ~/ 12;
      final m = totalMonths % 12;
      if (m == 0) {
        return '$y year${y == 1 ? '' : 's'}';
      }
      return '$y year${y == 1 ? '' : 's'}, $m month${m == 1 ? '' : 's'}';
    }
  }

  static int daysUntil(DateTime date) {
    return date.difference(DateTime.now()).inDays;
  }

  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    return date.isBefore(DateTime.now());
  }

  static bool isDueSoon(DateTime? date, {int withinDays = 30}) {
    if (date == null) return false;
    final days = daysUntil(date);
    return days >= 0 && days <= withinDays;
  }
}
