import 'package:timezone/timezone.dart' as tz;

/// Utility class for handling timezone-aware date operations
///
/// Provides methods for accurate monthly budget calculations across timezones
class TimezoneHandler {
  /// Get the start of the current month in the user's local timezone
  ///
  /// Returns DateTime at midnight on the first day of current month
  static DateTime getCurrentMonthStart() {
    final now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      1, // First day of month
      0, // Midnight
      0,
      0,
    );
  }

  /// Get the end of the current month in the user's local timezone
  ///
  /// Returns DateTime at 23:59:59.999 on the last day of current month
  static DateTime getCurrentMonthEnd() {
    final now = tz.TZDateTime.now(tz.local);
    final nextMonth = tz.TZDateTime(tz.local, now.year, now.month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  /// Get the start of a specific month in the user's local timezone
  ///
  /// [year] - The year (e.g., 2025)
  /// [month] - The month number (1-12)
  ///
  /// Returns DateTime at midnight on the first day of specified month
  static DateTime getMonthStart(int year, int month) {
    return tz.TZDateTime(
      tz.local,
      year,
      month,
      1,
      0,
      0,
      0,
    );
  }

  /// Get the end of a specific month in the user's local timezone
  ///
  /// [year] - The year (e.g., 2025)
  /// [month] - The month number (1-12)
  ///
  /// Returns DateTime at 23:59:59.999 on the last day of specified month
  static DateTime getMonthEnd(int year, int month) {
    final nextMonth = tz.TZDateTime(tz.local, year, month + 1, 1);
    return nextMonth.subtract(const Duration(milliseconds: 1));
  }

  /// Extract month and year from a DateTime
  ///
  /// Returns a record with (month, year) using user's local timezone
  static ({int month, int year}) extractMonthYear(DateTime date) {
    final localDate = tz.TZDateTime.from(date, tz.local);
    return (month: localDate.month, year: localDate.year);
  }

  /// Check if a date is in the current month
  ///
  /// Compares using user's local timezone for accuracy
  static bool isCurrentMonth(DateTime date) {
    final now = tz.TZDateTime.now(tz.local);
    final localDate = tz.TZDateTime.from(date, tz.local);
    return localDate.year == now.year && localDate.month == now.month;
  }

  /// Convert a UTC date to local timezone
  ///
  /// Useful for displaying dates from database (stored in UTC)
  static DateTime toLocal(DateTime utcDate) {
    return tz.TZDateTime.from(utcDate, tz.local);
  }

  /// Convert a local date to UTC for database storage
  ///
  /// Ensures consistent storage format in Supabase
  static DateTime toUtc(DateTime localDate) {
    final tzDate = tz.TZDateTime.from(localDate, tz.local);
    return tzDate.toUtc();
  }

  /// Get the current month and year in local timezone
  ///
  /// Returns a record with (month, year)
  static ({int month, int year}) getCurrentMonthYear() {
    final now = tz.TZDateTime.now(tz.local);
    return (month: now.month, year: now.year);
  }

  /// Format a month/year for display (e.g., "January 2025")
  ///
  /// [month] - The month number (1-12)
  /// [year] - The year (e.g., 2025)
  /// [locale] - Optional locale for month names (defaults to 'en')
  static String formatMonthYear(int month, int year, [String locale = 'en']) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12');
    }

    return '${monthNames[month - 1]} $year';
  }
}
