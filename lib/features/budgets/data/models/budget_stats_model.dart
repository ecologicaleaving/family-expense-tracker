import '../../../../core/utils/budget_calculator.dart';
import '../../domain/entities/budget_stats_entity.dart';

/// Budget statistics model for JSON serialization/deserialization.
///
/// Computed on-demand, not stored in database.
class BudgetStatsModel extends BudgetStatsEntity {
  const BudgetStatsModel({
    super.budgetId,
    super.budgetAmount,
    required super.spentAmount,
    super.remainingAmount,
    super.percentageUsed,
    required super.isOverBudget,
    required super.isNearLimit,
    required super.expenseCount,
  });

  /// Create BudgetStatsModel from aggregated query results.
  ///
  /// Calculates all derived fields from budget and expense data.
  factory BudgetStatsModel.fromQueryResult({
    String? budgetId,
    int? budgetAmount,
    required List<double> expenseAmounts,
  }) {
    // Calculate spent amount (rounded up to whole euros)
    final spentAmount = BudgetCalculator.calculateSpentAmount(expenseAmounts);

    // If no budget set, return stats with no budget
    if (budgetId == null || budgetAmount == null) {
      return BudgetStatsModel(
        spentAmount: spentAmount,
        isOverBudget: false,
        isNearLimit: false,
        expenseCount: expenseAmounts.length,
      );
    }

    // Calculate remaining amount
    final remainingAmount =
        BudgetCalculator.calculateRemainingAmount(budgetAmount, spentAmount);

    // Calculate percentage used
    final percentageUsed =
        BudgetCalculator.calculatePercentageUsed(budgetAmount, spentAmount);

    // Determine budget status flags
    final isOverBudget =
        BudgetCalculator.isOverBudget(budgetAmount, spentAmount);
    final isNearLimit = BudgetCalculator.isNearLimit(budgetAmount, spentAmount);

    return BudgetStatsModel(
      budgetId: budgetId,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      percentageUsed: percentageUsed,
      isOverBudget: isOverBudget,
      isNearLimit: isNearLimit,
      expenseCount: expenseAmounts.length,
    );
  }

  /// Create BudgetStatsModel from JSON (for caching purposes).
  factory BudgetStatsModel.fromJson(Map<String, dynamic> json) {
    return BudgetStatsModel(
      budgetId: json['budget_id'] as String?,
      budgetAmount: json['budget_amount'] as int?,
      spentAmount: json['spent_amount'] as int,
      remainingAmount: json['remaining_amount'] as int?,
      percentageUsed: json['percentage_used'] as double?,
      isOverBudget: json['is_over_budget'] as bool,
      isNearLimit: json['is_near_limit'] as bool,
      expenseCount: json['expense_count'] as int,
    );
  }

  /// Convert to JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'budget_id': budgetId,
      'budget_amount': budgetAmount,
      'spent_amount': spentAmount,
      'remaining_amount': remainingAmount,
      'percentage_used': percentageUsed,
      'is_over_budget': isOverBudget,
      'is_near_limit': isNearLimit,
      'expense_count': expenseCount,
    };
  }

  /// Create a BudgetStatsModel from a BudgetStatsEntity.
  factory BudgetStatsModel.fromEntity(BudgetStatsEntity entity) {
    return BudgetStatsModel(
      budgetId: entity.budgetId,
      budgetAmount: entity.budgetAmount,
      spentAmount: entity.spentAmount,
      remainingAmount: entity.remainingAmount,
      percentageUsed: entity.percentageUsed,
      isOverBudget: entity.isOverBudget,
      isNearLimit: entity.isNearLimit,
      expenseCount: entity.expenseCount,
    );
  }

  /// Convert to BudgetStatsEntity.
  BudgetStatsEntity toEntity() {
    return BudgetStatsEntity(
      budgetId: budgetId,
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      percentageUsed: percentageUsed,
      isOverBudget: isOverBudget,
      isNearLimit: isNearLimit,
      expenseCount: expenseCount,
    );
  }

  /// Create a copy with updated fields.
  @override
  BudgetStatsModel copyWith({
    String? budgetId,
    int? budgetAmount,
    int? spentAmount,
    int? remainingAmount,
    double? percentageUsed,
    bool? isOverBudget,
    bool? isNearLimit,
    int? expenseCount,
  }) {
    return BudgetStatsModel(
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
}
