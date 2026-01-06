// Domain Entity: Unified Budget Stats for Budget Dashboard
// Aggregates group, personal, and category budget statistics

import 'package:equatable/equatable.dart';

/// Category budget with spending data for unified view
class CategoryBudgetWithStats extends Equatable {
  final String categoryId;
  final String categoryName;
  final int categoryColor;
  final bool isGroupBudget; // true = group, false = personal
  final int budgetAmount; // in cents
  final int spentAmount; // in cents
  final double percentageUsed; // 0-100+
  final bool isOverBudget;
  final bool isNearLimit; // >= 80%
  final double? percentageOfGroupBudget; // for percentage-based budgets
  final String? budgetId;

  const CategoryBudgetWithStats({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.isGroupBudget,
    required this.budgetAmount,
    required this.spentAmount,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.isNearLimit,
    this.percentageOfGroupBudget,
    this.budgetId,
  });

  int get remainingAmount => budgetAmount - spentAmount;

  /// Status: healthy, warning, danger
  String get status {
    if (isOverBudget) return 'danger';
    if (isNearLimit) return 'warning';
    return 'healthy';
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryColor,
        isGroupBudget,
        budgetAmount,
        spentAmount,
        percentageUsed,
        isOverBudget,
        isNearLimit,
        percentageOfGroupBudget,
        budgetId,
      ];
}

/// Aggregated budget statistics for unified dashboard view
class UnifiedBudgetStatsEntity extends Equatable {
  // Combined totals (group + personal)
  final int totalBudgeted; // in cents
  final int totalSpent; // in cents
  final int totalRemaining; // can be negative
  final double overallPercentageUsed; // 0-100+

  // Group-only stats
  final int? groupBudget; // in cents, null if not set
  final int groupSpent; // in cents

  // Personal-only stats
  final int? personalBudget; // in cents, null if not set
  final int personalSpent; // in cents

  // Alert info
  final int alertCategoriesCount; // categories at warning or over budget
  final List<CategoryBudgetWithStats> alertCategories;

  // Top spending (top 5)
  final List<CategoryBudgetWithStats> topSpendingCategories;

  // All categories with budgets (for grid)
  final List<CategoryBudgetWithStats> allCategories;

  // Active stats
  final int activeCategoriesCount; // categories with budgets set

  // Month/Year context
  final int month; // 1-12
  final int year; // e.g., 2026

  const UnifiedBudgetStatsEntity({
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallPercentageUsed,
    this.groupBudget,
    required this.groupSpent,
    this.personalBudget,
    required this.personalSpent,
    required this.alertCategoriesCount,
    required this.alertCategories,
    required this.topSpendingCategories,
    required this.allCategories,
    required this.activeCategoriesCount,
    required this.month,
    required this.year,
  });

  /// Check if any budgets are set
  bool get hasBudgets => totalBudgeted > 0;

  /// Check if there are any alerts
  bool get hasAlerts => alertCategoriesCount > 0;

  /// Check if overall is over budget
  bool get isOverBudget => hasBudgets && totalSpent >= totalBudgeted;

  /// Check if overall is near limit (>= 80%)
  bool get isNearLimit => hasBudgets && overallPercentageUsed >= 80;

  /// Empty state factory
  factory UnifiedBudgetStatsEntity.empty({
    required int month,
    required int year,
  }) {
    return UnifiedBudgetStatsEntity(
      totalBudgeted: 0,
      totalSpent: 0,
      totalRemaining: 0,
      overallPercentageUsed: 0,
      groupSpent: 0,
      personalSpent: 0,
      alertCategoriesCount: 0,
      alertCategories: const [],
      topSpendingCategories: const [],
      allCategories: const [],
      activeCategoriesCount: 0,
      month: month,
      year: year,
    );
  }

  @override
  List<Object?> get props => [
        totalBudgeted,
        totalSpent,
        totalRemaining,
        overallPercentageUsed,
        groupBudget,
        groupSpent,
        personalBudget,
        personalSpent,
        alertCategoriesCount,
        alertCategories,
        topSpendingCategories,
        allCategories,
        activeCategoriesCount,
        month,
        year,
      ];

  @override
  String toString() {
    return 'UnifiedBudgetStatsEntity(total: €${totalBudgeted / 100}, spent: €${totalSpent / 100}, remaining: €${totalRemaining / 100}, alerts: $alertCategoriesCount)';
  }
}
