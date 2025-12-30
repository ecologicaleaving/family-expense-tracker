/// Application-wide constants and configuration values.

import 'package:flutter/material.dart';

/// Expense categories with Italian labels
enum ExpenseCategory {
  food('food', 'Alimentari', '🍕', Icons.restaurant, Colors.orange),
  utilities('utilities', 'Utenze', '💡', Icons.lightbulb, Colors.amber),
  transport('transport', 'Trasporti', '🚗', Icons.directions_car, Colors.blue),
  healthcare('healthcare', 'Salute', '🏥', Icons.local_hospital, Colors.red),
  entertainment('entertainment', 'Svago', '🎬', Icons.movie, Colors.purple),
  household('household', 'Casa', '🏠', Icons.home, Colors.teal),
  altro('other', 'Altro', '📦', Icons.category, Colors.grey);

  const ExpenseCategory(this.value, this.label, this.emoji, this.icon, this.color);

  /// Database/JSON value (also used as apiValue)
  final String value;

  /// API value (alias for value)
  String get apiValue => value;

  /// Italian display label
  final String label;

  /// Emoji icon for display
  final String emoji;

  /// Material icon for display
  final IconData icon;

  /// Color for charts
  final Color color;

  /// Get category from string value
  static ExpenseCategory fromValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExpenseCategory.altro,
    );
  }
}

/// Dashboard time period filters
enum TimePeriod {
  week('week', 'Settimana'),
  month('month', 'Mese'),
  year('year', 'Anno');

  const TimePeriod(this.value, this.label);

  final String value;
  final String label;
}

/// Validation rules
class ValidationRules {
  ValidationRules._();

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum display name length
  static const int maxDisplayNameLength = 50;

  /// Minimum display name length
  static const int minDisplayNameLength = 2;

  /// Maximum group name length
  static const int maxGroupNameLength = 30;

  /// Maximum merchant name length
  static const int maxMerchantLength = 100;

  /// Maximum notes length
  static const int maxNotesLength = 500;

  /// Minimum expense amount in EUR
  static const double minExpenseAmount = 0.01;

  /// Maximum expense amount in EUR
  static const double maxExpenseAmount = 99999.99;

  /// Invite code length
  static const int inviteCodeLength = 6;

  /// Invite code validity in days
  static const int inviteCodeValidityDays = 7;

  /// Maximum group members
  static const int maxGroupMembers = 10;

  /// Maximum receipt image size in bytes (5MB)
  static const int maxReceiptImageSize = 5 * 1024 * 1024;
}

/// App-wide UI constants
class AppConstants {
  AppConstants._();

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Maximum items to load at once
  static const int maxPageSize = 50;

  /// Animation duration in milliseconds
  static const int animationDurationMs = 300;

  /// Default currency
  static const String defaultCurrency = 'EUR';

  /// Default locale
  static const String defaultLocale = 'it_IT';
}
