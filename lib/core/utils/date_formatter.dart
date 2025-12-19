import 'package:intl/intl.dart';

/// Date and time formatting utilities with Italian locale support.
class DateFormatter {
  DateFormatter._();

  // Date formatters
  static final _fullDateFormat = DateFormat('d MMMM yyyy', 'it_IT');
  static final _shortDateFormat = DateFormat('d MMM yyyy', 'it_IT');
  static final _dayMonthFormat = DateFormat('d MMMM', 'it_IT');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'it_IT');
  static final _dayOfWeekFormat = DateFormat('EEEE', 'it_IT');
  static final _shortDayOfWeekFormat = DateFormat('EEE', 'it_IT');
  static final _numericDateFormat = DateFormat('dd/MM/yyyy', 'it_IT');
  static final _isoDateFormat = DateFormat('yyyy-MM-dd');

  // Time formatters
  static final _timeFormat = DateFormat('HH:mm', 'it_IT');
  static final _timeWithSecondsFormat = DateFormat('HH:mm:ss', 'it_IT');

  // Combined formatters
  static final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'it_IT');
  static final _fullDateTimeFormat =
      DateFormat('EEEE d MMMM yyyy, HH:mm', 'it_IT');

  /// Format as full date (e.g., "15 dicembre 2024")
  static String formatFullDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// Format as short date (e.g., "15 dic 2024")
  static String formatShortDate(DateTime date) {
    return _shortDateFormat.format(date);
  }

  /// Format as day and month only (e.g., "15 dicembre")
  static String formatDayMonth(DateTime date) {
    return _dayMonthFormat.format(date);
  }

  /// Format as month and year (e.g., "dicembre 2024")
  static String formatMonthYear(DateTime date) {
    return _monthYearFormat.format(date);
  }

  /// Format as day of week (e.g., "lunedì")
  static String formatDayOfWeek(DateTime date) {
    return _dayOfWeekFormat.format(date);
  }

  /// Format as short day of week (e.g., "lun")
  static String formatShortDayOfWeek(DateTime date) {
    return _shortDayOfWeekFormat.format(date);
  }

  /// Format as numeric date (e.g., "15/12/2024")
  static String formatNumericDate(DateTime date) {
    return _numericDateFormat.format(date);
  }

  /// Format as ISO date (e.g., "2024-12-15")
  static String formatIsoDate(DateTime date) {
    return _isoDateFormat.format(date);
  }

  /// Format time only (e.g., "14:30")
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime);
  }

  /// Format time with seconds (e.g., "14:30:45")
  static String formatTimeWithSeconds(DateTime dateTime) {
    return _timeWithSecondsFormat.format(dateTime);
  }

  /// Format as date and time (e.g., "15 dic 2024, 14:30")
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// Format as full date and time (e.g., "lunedì 15 dicembre 2024, 14:30")
  static String formatFullDateTime(DateTime dateTime) {
    return _fullDateTimeFormat.format(dateTime);
  }

  /// Format as relative time (e.g., "oggi", "ieri", "2 giorni fa")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Oggi';
    } else if (difference == 1) {
      return 'Ieri';
    } else if (difference == 2) {
      return "L'altro ieri";
    } else if (difference > 0 && difference < 7) {
      return '$difference giorni fa';
    } else if (difference == 7) {
      return 'Una settimana fa';
    } else if (difference > 7 && difference < 30) {
      final weeks = (difference / 7).floor();
      return weeks == 1 ? 'Una settimana fa' : '$weeks settimane fa';
    } else if (difference >= 30 && difference < 365) {
      final months = (difference / 30).floor();
      return months == 1 ? 'Un mese fa' : '$months mesi fa';
    } else if (difference >= 365) {
      final years = (difference / 365).floor();
      return years == 1 ? 'Un anno fa' : '$years anni fa';
    } else if (difference == -1) {
      return 'Domani';
    } else if (difference < -1) {
      return 'Tra ${-difference} giorni';
    }

    return formatShortDate(date);
  }

  /// Format as relative date (alias for formatRelativeWithDate)
  static String formatRelativeDate(DateTime date) {
    return formatRelativeWithDate(date);
  }

  /// Format as relative with date fallback for older dates
  static String formatRelativeWithDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) {
      return 'Oggi';
    } else if (difference == 1) {
      return 'Ieri';
    } else if (difference > 1 && difference < 7) {
      return formatDayOfWeek(date);
    } else {
      return formatShortDate(date);
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: daysFromMonday)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final daysUntilSunday = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: daysUntilSunday)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Get start of year
  static DateTime startOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// Get end of year
  static DateTime endOfYear(DateTime date) {
    return DateTime(date.year, 12, 31, 23, 59, 59, 999);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Check if date is in current week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfCurrentWeek = startOfWeek(now);
    final endOfCurrentWeek = endOfWeek(now);
    return date.isAfter(startOfCurrentWeek.subtract(const Duration(seconds: 1))) &&
        date.isBefore(endOfCurrentWeek.add(const Duration(seconds: 1)));
  }

  /// Check if date is in current month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is in current year
  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  /// Parse date from ISO string
  static DateTime? parseIsoDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    return DateTime.tryParse(dateString);
  }

  /// Parse date from numeric format (dd/MM/yyyy)
  static DateTime? parseNumericDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return _numericDateFormat.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Get month name in Italian
  static String getMonthName(int month) {
    const months = [
      'gennaio',
      'febbraio',
      'marzo',
      'aprile',
      'maggio',
      'giugno',
      'luglio',
      'agosto',
      'settembre',
      'ottobre',
      'novembre',
      'dicembre',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  /// Get day name in Italian
  static String getDayName(int weekday) {
    const days = [
      'lunedì',
      'martedì',
      'mercoledì',
      'giovedì',
      'venerdì',
      'sabato',
      'domenica',
    ];
    if (weekday < 1 || weekday > 7) return '';
    return days[weekday - 1];
  }
}
