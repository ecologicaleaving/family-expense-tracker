import 'package:equatable/equatable.dart';

/// Personal budget entity representing a monthly budget for an individual user.
///
/// **DEPRECATED**: This entity is deprecated in favor of the category-only budget system.
/// Personal budget totals are now calculated as SUM of user's category contributions.
/// Use [ComputedBudgetTotals] for new implementations.
///
/// This entity is kept for:
/// - Historical data access
/// - Backward compatibility during migration
/// - Reading deprecated budget records
///
/// Do not use this for new budget creation. Use category budgets with member contributions instead.
///
/// Tracks user's total spending including both personal expenses and their group expenses.
@Deprecated(
  'Use category budgets with member contributions and ComputedBudgetTotals instead. '
  'Personal budget is now calculated as SUM of user contributions.',
)
class PersonalBudgetEntity extends Equatable {
  const PersonalBudgetEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique budget identifier
  final String id;

  /// The user this budget belongs to
  final String userId;

  /// Budget amount in cents (e.g., 50000 = €500.00)
  /// Stored as cents to avoid floating-point precision errors
  final int amount;

  /// Month number (1-12)
  final int month;

  /// Year (e.g., 2025)
  final int year;

  /// When the budget was created
  final DateTime createdAt;

  /// When the budget was last updated
  final DateTime updatedAt;

  /// Get formatted amount string (converts cents to euros)
  String get formattedAmount => '€${(amount / 100).toStringAsFixed(2)}';

  /// Get formatted month/year string (e.g., "January 2025")
  String get formattedMonthYear {
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
    return '${monthNames[month - 1]} $year';
  }

  /// Check if this budget is for the current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Create an empty budget (for initial state)
  factory PersonalBudgetEntity.empty() {
    final now = DateTime.now();
    return PersonalBudgetEntity(
      id: '',
      userId: '',
      amount: 0,
      month: now.month,
      year: now.year,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if this is an empty budget
  bool get isEmpty => id.isEmpty;

  /// Check if this is a valid budget
  bool get isNotEmpty => id.isNotEmpty;

  /// Create a copy with updated fields
  PersonalBudgetEntity copyWith({
    String? id,
    String? userId,
    int? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalBudgetEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        month,
        year,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'PersonalBudgetEntity(id: $id, amount: $formattedAmount, period: $formattedMonthYear)';
  }
}
