import 'package:equatable/equatable.dart';

/// Group budget entity representing a monthly budget for a family group.
///
/// **DEPRECATED**: This entity is deprecated in favor of the category-only budget system.
/// Group budget totals are now calculated as SUM of category budgets.
/// Use [ComputedBudgetTotals] for new implementations.
///
/// This entity is kept for:
/// - Historical data access
/// - Backward compatibility during migration
/// - Reading deprecated budget records
///
/// Do not use this for new budget creation. Use category budgets instead.
@Deprecated(
  'Use category budgets and ComputedBudgetTotals instead. '
  'Group budget is now calculated as SUM of category budgets.',
)
class GroupBudgetEntity extends Equatable {
  const GroupBudgetEntity({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Unique budget identifier
  final String id;

  /// The family group this budget belongs to
  final String groupId;

  /// Budget amount in cents (e.g., 50000 = €500.00)
  /// Stored as cents to avoid floating-point precision errors
  final int amount;

  /// Month number (1-12)
  final int month;

  /// Year (e.g., 2025)
  final int year;

  /// User ID of who created/set the budget (must be group admin)
  final String createdBy;

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
  factory GroupBudgetEntity.empty() {
    final now = DateTime.now();
    return GroupBudgetEntity(
      id: '',
      groupId: '',
      amount: 0,
      month: now.month,
      year: now.year,
      createdBy: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if this is an empty budget
  bool get isEmpty => id.isEmpty;

  /// Check if this is a valid budget
  bool get isNotEmpty => id.isNotEmpty;

  /// Create a copy with updated fields
  GroupBudgetEntity copyWith({
    String? id,
    String? groupId,
    int? amount,
    int? month,
    int? year,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupBudgetEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        amount,
        month,
        year,
        createdBy,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'GroupBudgetEntity(id: $id, amount: $formattedAmount, period: $formattedMonthYear)';
  }
}
