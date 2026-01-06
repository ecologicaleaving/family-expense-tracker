import '../../../../core/enums/budget_type.dart';

/// Represents a family member's contribution to a category budget
///
/// A member can contribute either:
/// - A fixed amount in cents (e.g., €100.00 = 10000 cents)
/// - A percentage of the category's group budget (e.g., 25%)
///
/// The calculated amount is automatically computed based on the type.
class MemberContribution {
  /// User ID of the contributing member
  final String userId;

  /// Display name of the contributing member
  final String userName;

  /// Type of contribution (FIXED or PERCENTAGE)
  final BudgetType type;

  /// Fixed amount in cents (only if type == FIXED)
  ///
  /// Example: €100.00 = 10000 cents
  final int? fixedAmount;

  /// Percentage of category budget (only if type == PERCENTAGE)
  ///
  /// Value range: 0.0 - 100.0
  /// Example: 25.0 means 25% of the category budget
  final double? percentage;

  /// Calculated budget amount in cents
  ///
  /// For FIXED type: equals fixedAmount
  /// For PERCENTAGE type: calculated as (percentage / 100) * categoryGroupBudget
  final int calculatedAmount;

  const MemberContribution({
    required this.userId,
    required this.userName,
    required this.type,
    this.fixedAmount,
    this.percentage,
    required this.calculatedAmount,
  });

  /// Creates a fixed-amount contribution
  ///
  /// Example:
  /// ```dart
  /// MemberContribution.fixed(
  ///   userId: 'user123',
  ///   userName: 'Mario',
  ///   amount: 10000, // €100.00
  /// )
  /// ```
  factory MemberContribution.fixed({
    required String userId,
    required String userName,
    required int amount,
  }) {
    return MemberContribution(
      userId: userId,
      userName: userName,
      type: BudgetType.fixed,
      fixedAmount: amount,
      percentage: null,
      calculatedAmount: amount,
    );
  }

  /// Creates a percentage-based contribution
  ///
  /// Example:
  /// ```dart
  /// MemberContribution.percentage(
  ///   userId: 'user123',
  ///   userName: 'Mario',
  ///   percentage: 25.0, // 25%
  ///   categoryGroupBudget: 100000, // €1000.00
  /// )
  /// // calculatedAmount will be 25000 (€250.00)
  /// ```
  factory MemberContribution.percentage({
    required String userId,
    required String userName,
    required double percentage,
    required int categoryGroupBudget,
  }) {
    final calculatedAmount = ((percentage / 100.0) * categoryGroupBudget).round();
    return MemberContribution(
      userId: userId,
      userName: userName,
      type: BudgetType.percentage,
      fixedAmount: null,
      percentage: percentage,
      calculatedAmount: calculatedAmount,
    );
  }

  /// Whether this is a fixed amount contribution
  bool get isFixed => type.isFixed;

  /// Whether this is a percentage contribution
  bool get isPercentage => type.isPercentage;

  /// Display string for the contribution value
  ///
  /// Examples:
  /// - Fixed: "€100.00"
  /// - Percentage: "25.0% (€250.00)"
  String get displayValue {
    if (isFixed) {
      return '€${(calculatedAmount / 100).toStringAsFixed(2)}';
    } else {
      return '${percentage!.toStringAsFixed(1)}% (€${(calculatedAmount / 100).toStringAsFixed(2)})';
    }
  }

  /// Creates a copy with updated fields
  MemberContribution copyWith({
    String? userId,
    String? userName,
    BudgetType? type,
    int? fixedAmount,
    double? percentage,
    int? calculatedAmount,
  }) {
    return MemberContribution(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      percentage: percentage ?? this.percentage,
      calculatedAmount: calculatedAmount ?? this.calculatedAmount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemberContribution &&
        other.userId == userId &&
        other.userName == userName &&
        other.type == type &&
        other.fixedAmount == fixedAmount &&
        other.percentage == percentage &&
        other.calculatedAmount == calculatedAmount;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      userName,
      type,
      fixedAmount,
      percentage,
      calculatedAmount,
    );
  }

  @override
  String toString() {
    return 'MemberContribution(userId: $userId, userName: $userName, '
        'type: $type, displayValue: $displayValue)';
  }

  /// Converts to JSON map for serialization
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'budget_type': type.value,
      'fixed_amount': fixedAmount,
      'percentage': percentage,
      'calculated_amount': calculatedAmount,
    };
  }

  /// Creates from JSON map
  factory MemberContribution.fromJson(Map<String, dynamic> json) {
    return MemberContribution(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      type: BudgetType.fromString(json['budget_type'] as String),
      fixedAmount: json['fixed_amount'] as int?,
      percentage: (json['percentage'] as num?)?.toDouble(),
      calculatedAmount: json['calculated_amount'] as int,
    );
  }
}
