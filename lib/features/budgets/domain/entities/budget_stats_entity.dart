import 'package:equatable/equatable.dart';

/// Budget statistics entity representing calculated budget consumption data.
///
/// Computed on-demand from budget and expense data, not stored in database.
class BudgetStatsEntity extends Equatable {
  const BudgetStatsEntity({
    this.budgetId,
    this.budgetAmount,
    required this.spentAmount,
    this.remainingAmount,
    this.percentageUsed,
    required this.isOverBudget,
    required this.isNearLimit,
    required this.expenseCount,
  });

  /// Budget ID (null if no budget set)
  final String? budgetId;

  /// Budget amount in cents (null if no budget set)
  /// e.g., 50000 = €500.00
  final int? budgetAmount;

  /// Spent amount in cents (converted from expense totals)
  /// e.g., 69000 = €690.00
  final int spentAmount;

  /// Remaining amount in cents (null if no budget set, can be negative if over budget)
  final int? remainingAmount;

  /// Percentage of budget used (0-100+, null if no budget set)
  final double? percentageUsed;

  /// True if spent amount >= budget amount
  final bool isOverBudget;

  /// True if >= 80% of budget used
  final bool isNearLimit;

  /// Number of expenses included in calculation
  final int expenseCount;

  /// Check if a budget is set
  bool get hasBudget => budgetId != null && budgetAmount != null;

  /// Get budget status as string
  String get status {
    if (!hasBudget) return 'no_budget';
    if (isOverBudget) return 'over_budget';
    if (isNearLimit) return 'warning';
    return 'healthy';
  }

  /// Get formatted budget amount string
  String get formattedBudgetAmount {
    if (budgetAmount == null) return 'No budget set';
    return '€$budgetAmount';
  }

  /// Get formatted spent amount string
  String get formattedSpentAmount => '€$spentAmount';

  /// Get formatted remaining amount string
  String get formattedRemainingAmount {
    if (remainingAmount == null) return 'N/A';
    final absAmount = remainingAmount!.abs();
    return remainingAmount! < 0 ? '-€$absAmount' : '€$remainingAmount';
  }

  /// Get formatted percentage string
  String get formattedPercentage {
    if (percentageUsed == null) return 'N/A';
    return '${percentageUsed!.toStringAsFixed(1)}%';
  }

  /// Create empty stats (no budget, no expenses)
  factory BudgetStatsEntity.empty() {
    return const BudgetStatsEntity(
      spentAmount: 0,
      isOverBudget: false,
      isNearLimit: false,
      expenseCount: 0,
    );
  }

  /// Create stats for when budget is not set
  factory BudgetStatsEntity.noBudget({
    required int spentAmount,
    required int expenseCount,
  }) {
    return BudgetStatsEntity(
      spentAmount: spentAmount,
      isOverBudget: false,
      isNearLimit: false,
      expenseCount: expenseCount,
    );
  }

  /// Create a copy with updated fields
  BudgetStatsEntity copyWith({
    String? budgetId,
    int? budgetAmount,
    int? spentAmount,
    int? remainingAmount,
    double? percentageUsed,
    bool? isOverBudget,
    bool? isNearLimit,
    int? expenseCount,
  }) {
    return BudgetStatsEntity(
      budgetId: budgetId ?? this.budgetId,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      percentageUsed: percentageUsed ?? this.percentageUsed,
      isOverBudget: isOverBudget ?? this.isOverBudget,
      isNearLimit: isNearLimit ?? this.isNearLimit,
      expenseCount: expenseCount ?? this.expenseCount,
    );
  }

  @override
  List<Object?> get props => [
        budgetId,
        budgetAmount,
        spentAmount,
        remainingAmount,
        percentageUsed,
        isOverBudget,
        isNearLimit,
        expenseCount,
      ];

  @override
  String toString() {
    return 'BudgetStatsEntity(budget: $formattedBudgetAmount, spent: $formattedSpentAmount, remaining: $formattedRemainingAmount, status: $status)';
  }
}
