import 'package:intl/intl.dart';

/// Utility class for handling currency conversions between cents and euros
///
/// CRITICAL: All monetary values in the system MUST be stored as cents (INT)
/// internally. Only convert to euros (DOUBLE) for display purposes.
///
/// Examples:
/// - €5000.00 = 500000 cents
/// - €123.45 = 12345 cents
/// - €0.99 = 99 cents
class CurrencyUtils {
  /// Number of cents in one euro
  static const int CENTS_PER_EURO = 100;

  /// Converts cents (INT) to euros (DOUBLE)
  ///
  /// Example:
  /// ```dart
  /// centsToEuro(500000) // Returns 5000.0
  /// centsToEuro(12345)  // Returns 123.45
  /// ```
  static double centsToEuro(int cents) => cents / CENTS_PER_EURO;

  /// Converts euros (DOUBLE) to cents (INT)
  ///
  /// Uses rounding to handle floating point precision issues.
  ///
  /// Example:
  /// ```dart
  /// euroToCents(5000.0)  // Returns 500000
  /// euroToCents(123.45)  // Returns 12345
  /// ```
  static int euroToCents(double euro) => (euro * CENTS_PER_EURO).round();

  /// Formats cents as a currency string for display
  ///
  /// Always shows 2 decimal places with euro symbol.
  ///
  /// Example:
  /// ```dart
  /// formatCents(500000)  // Returns "€5000.00"
  /// formatCents(12345)   // Returns "€123.45"
  /// formatCents(99)      // Returns "€0.99"
  /// ```
  static String formatCents(int cents) {
    final euro = centsToEuro(cents);
    return '€${euro.toStringAsFixed(2)}';
  }

  /// Formats cents as a compact currency string (no decimals if whole euros)
  ///
  /// Shows decimals only when needed.
  ///
  /// Example:
  /// ```dart
  /// formatCentsCompact(500000)  // Returns "€5.000"
  /// formatCentsCompact(12345)   // Returns "€123"
  /// formatCentsCompact(10000)   // Returns "€100"
  /// ```
  static String formatCentsCompact(int cents) {
    final euro = centsToEuro(cents);
    // Always round to nearest euro, no decimals
    final formatter = NumberFormat.currency(
      locale: 'it_IT',
      symbol: '€',
      decimalDigits: 0,
    );
    return formatter.format(euro.round());
  }

  /// Parses user input string to cents
  ///
  /// Accepts various input formats:
  /// - "1500" → 150000 cents (€1500.00)
  /// - "123.45" → 12345 cents (€123.45)
  /// - "0.99" → 99 cents (€0.99)
  ///
  /// Returns null if input cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// parseCentsFromInput("1500")    // Returns 150000
  /// parseCentsFromInput("123.45")  // Returns 12345
  /// parseCentsFromInput("invalid") // Returns null
  /// ```
  static int? parseCentsFromInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    final euro = double.tryParse(trimmed);
    if (euro == null) return null;
    if (euro < 0) return null; // No negative amounts

    return euroToCents(euro);
  }

  /// Validates that a cents value is positive and within reasonable range
  ///
  /// Maximum budget: €10,000,000 (1 billion cents)
  ///
  /// Returns true if valid, false otherwise.
  static bool isValidCentsAmount(int cents) {
    return cents >= 0 && cents <= 1000000000; // Max €10M
  }

  /// Calculates percentage of budget used
  ///
  /// Returns value between 0.0 and 100.0+ (can exceed 100 if over budget)
  ///
  /// Example:
  /// ```dart
  /// calculatePercentageUsed(100000, 50000)  // Returns 50.0
  /// calculatePercentageUsed(100000, 150000) // Returns 150.0 (over budget)
  /// calculatePercentageUsed(0, 50000)       // Returns 0.0 (avoid division by zero)
  /// ```
  static double calculatePercentageUsed(int budgetCents, int spentCents) {
    if (budgetCents <= 0) return 0.0;
    return (spentCents / budgetCents) * 100.0;
  }
}
