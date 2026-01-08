import 'package:equatable/equatable.dart';

import 'budget_validation_issue_entity.dart';
import 'category_budget_with_members_entity.dart';
import 'group_budget_entity.dart';

/// Aggregate statistics for the entire budget composition
class BudgetStats extends Equatable {
  /// Total budgeted across all categories (in cents)
  final int totalCategoryBudgets;

  /// Total spent across all categories (in cents)
  final int totalSpent;

  /// Total remaining across all categories (can be negative)
  final int totalRemaining;

  /// Percentage of total budgets used (0-100+)
  final double overallPercentageUsed;

  /// Number of categories with budgets set
  final int categoriesWithBudgets;

  /// Number of categories at warning or over budget
  final int alertCategoriesCount;

  /// Number of categories over budget
  final int overBudgetCount;

  /// Number of categories near limit (>= 80%)
  final int nearLimitCount;

  const BudgetStats({
    required this.totalCategoryBudgets,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallPercentageUsed,
    required this.categoriesWithBudgets,
    required this.alertCategoriesCount,
    required this.overBudgetCount,
    required this.nearLimitCount,
  });

  /// Creates empty stats (no budgets)
  factory BudgetStats.empty() {
    return const BudgetStats(
      totalCategoryBudgets: 0,
      totalSpent: 0,
      totalRemaining: 0,
      overallPercentageUsed: 0,
      categoriesWithBudgets: 0,
      alertCategoriesCount: 0,
      overBudgetCount: 0,
      nearLimitCount: 0,
    );
  }

  /// Whether any budgets are set
  bool get hasBudgets => totalCategoryBudgets > 0;

  /// Whether there are any alerts
  bool get hasAlerts => alertCategoriesCount > 0;

  /// Whether overall spending is over budget
  bool get isOverBudget => hasBudgets && totalSpent >= totalCategoryBudgets;

  /// Whether overall spending is near limit
  bool get isNearLimit => hasBudgets && overallPercentageUsed >= 80.0;

  @override
  List<Object?> get props => [
        totalCategoryBudgets,
        totalSpent,
        totalRemaining,
        overallPercentageUsed,
        categoriesWithBudgets,
        alertCategoriesCount,
        overBudgetCount,
        nearLimitCount,
      ];
}

/// Complete budget composition for a group in a specific month
///
/// Aggregates all budget information:
/// - Group budget total (calculated from category budgets)
/// - Category budgets with member contributions
/// - Aggregate spending statistics
/// - Validation issues
///
/// This is the main entity used by the unified budget system.
class BudgetComposition extends Equatable {
  /// The calculated group budget total in cents
  ///
  /// Computed as SUM of all category budget amounts.
  /// This replaces the manual GroupBudgetEntity with a calculated value.
  final int calculatedGroupBudget;

  /// Whether a manual group budget exists (deprecated, for transition period only)
  ///
  /// Used during migration to show both manual and calculated budgets.
  /// Will be removed once migration is complete.
  final bool hasManualGroupBudget;

  /// All category budgets with their member contributions
  ///
  /// Each category can have:
  /// - A group-level budget
  /// - Individual member contributions (fixed or percentage-based)
  /// - Spending statistics
  final List<CategoryBudgetWithMembers> categoryBudgets;

  /// Aggregate statistics across all category budgets
  final BudgetStats stats;

  /// Validation issues found in this budget composition
  ///
  /// Includes errors (blocking) and warnings (non-blocking):
  /// - Over-allocation (category budgets > group budget)
  /// - Percentage overflow (member percentages > 100%)
  /// - Invalid percentage values (< 0 or > 100)
  /// - Missing group budget
  final List<BudgetValidationIssue> issues;

  /// Month (1-12)
  final int month;

  /// Year (e.g., 2026)
  final int year;

  /// Group ID
  final String groupId;

  const BudgetComposition({
    required this.calculatedGroupBudget,
    this.hasManualGroupBudget = false,
    required this.categoryBudgets,
    required this.stats,
    required this.issues,
    required this.month,
    required this.year,
    required this.groupId,
  });

  /// Creates an empty composition (no budgets set)
  factory BudgetComposition.empty({
    required String groupId,
    required int month,
    required int year,
  }) {
    return BudgetComposition(
      calculatedGroupBudget: 0,
      hasManualGroupBudget: false,
      categoryBudgets: const [],
      stats: BudgetStats.empty(),
      issues: const [],
      month: month,
      year: year,
      groupId: groupId,
    );
  }

  /// Whether the group budget is set
  bool get hasGroupBudget => calculatedGroupBudget > 0;

  /// Group budget amount in cents (0 if not set)
  int get groupBudgetAmount => calculatedGroupBudget;

  /// Whether any category budgets are set
  bool get hasCategoryBudgets => categoryBudgets.isNotEmpty;

  /// Whether there are any validation issues
  bool get hasIssues => issues.isNotEmpty;

  /// Validation errors only (blocking issues)
  List<BudgetValidationIssue> get errors =>
      issues.where((issue) => issue.isError).toList();

  /// Validation warnings only (non-blocking issues)
  List<BudgetValidationIssue> get warnings =>
      issues.where((issue) => issue.isWarning).toList();

  /// Whether there are any errors (blocks operations)
  bool get hasErrors => errors.isNotEmpty;

  /// Whether there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Categories that are over budget or near limit
  List<CategoryBudgetWithMembers> get alertCategories {
    return categoryBudgets
        .where((cat) => cat.stats.isOverBudget || cat.stats.isNearLimit)
        .toList()
      ..sort((a, b) {
        // Over budget first
        if (a.stats.isOverBudget && !b.stats.isOverBudget) return -1;
        if (!a.stats.isOverBudget && b.stats.isOverBudget) return 1;
        // Then by percentage used
        return b.stats.percentageUsed.compareTo(a.stats.percentageUsed);
      });
  }

  /// Top spending categories (top 5 by spent amount)
  List<CategoryBudgetWithMembers> get topSpendingCategories {
    final sorted = List<CategoryBudgetWithMembers>.from(categoryBudgets)
      ..sort((a, b) => b.stats.spentAmount.compareTo(a.stats.spentAmount));
    return sorted.take(5).toList();
  }

  /// Unallocated group budget (group budget minus sum of category budgets)
  ///
  /// Can be negative if category budgets exceed group budget (over-allocation).
  int get unallocatedGroupBudget {
    if (!hasGroupBudget) return 0;
    return groupBudgetAmount - stats.totalCategoryBudgets;
  }

  /// Whether category budgets exceed group budget
  bool get isOverAllocated => hasGroupBudget && unallocatedGroupBudget < 0;

  /// Percentage of group budget allocated to categories
  double get allocationPercentage {
    if (!hasGroupBudget || groupBudgetAmount == 0) return 0.0;
    return (stats.totalCategoryBudgets / groupBudgetAmount) * 100.0;
  }

  /// Whether all group budget is allocated
  bool get isFullyAllocated {
    return hasGroupBudget &&
           allocationPercentage >= 99.0 &&
           allocationPercentage <= 101.0; // Allow 1% margin
  }

  /// Creates a copy with updated fields
  BudgetComposition copyWith({
    int? calculatedGroupBudget,
    bool? hasManualGroupBudget,
    List<CategoryBudgetWithMembers>? categoryBudgets,
    BudgetStats? stats,
    List<BudgetValidationIssue>? issues,
    int? month,
    int? year,
    String? groupId,
  }) {
    return BudgetComposition(
      calculatedGroupBudget: calculatedGroupBudget ?? this.calculatedGroupBudget,
      hasManualGroupBudget: hasManualGroupBudget ?? this.hasManualGroupBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      stats: stats ?? this.stats,
      issues: issues ?? this.issues,
      month: month ?? this.month,
      year: year ?? this.year,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  List<Object?> get props => [
        calculatedGroupBudget,
        hasManualGroupBudget,
        categoryBudgets,
        stats,
        issues,
        month,
        year,
        groupId,
      ];

  @override
  String toString() {
    return 'BudgetComposition('
        'groupBudget: €${groupBudgetAmount / 100}, '
        'categories: ${categoryBudgets.length}, '
        'allocated: ${allocationPercentage.toStringAsFixed(1)}%, '
        'spent: €${stats.totalSpent / 100}, '
        'issues: ${issues.length}'
        ')';
  }
}
