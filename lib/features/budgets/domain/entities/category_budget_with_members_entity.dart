import 'package:equatable/equatable.dart';

import 'member_contribution_entity.dart';

/// Statistics for a category budget
class CategoryStats extends Equatable {
  /// Total spent in this category (in cents)
  final int spentAmount;

  /// Remaining budget (budgetAmount - spentAmount, can be negative)
  final int remainingAmount;

  /// Percentage of budget used (0-100+)
  final double percentageUsed;

  /// Whether spending has exceeded the budget
  final bool isOverBudget;

  /// Whether spending is near the limit (>= 80%)
  final bool isNearLimit;

  const CategoryStats({
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.isOverBudget,
    required this.isNearLimit,
  });

  /// Creates empty stats (no spending)
  factory CategoryStats.empty() {
    return const CategoryStats(
      spentAmount: 0,
      remainingAmount: 0,
      percentageUsed: 0,
      isOverBudget: false,
      isNearLimit: false,
    );
  }

  /// Creates stats from budget and spent amounts
  factory CategoryStats.fromAmounts({
    required int budgetAmount,
    required int spentAmount,
  }) {
    final remaining = budgetAmount - spentAmount;
    final percentageUsed = budgetAmount > 0
        ? (spentAmount / budgetAmount) * 100.0
        : 0.0;
    final isOver = spentAmount >= budgetAmount && budgetAmount > 0;
    final isNear = percentageUsed >= 80.0 && !isOver;

    return CategoryStats(
      spentAmount: spentAmount,
      remainingAmount: remaining,
      percentageUsed: percentageUsed,
      isOverBudget: isOver,
      isNearLimit: isNear,
    );
  }

  /// Status: healthy, warning, or danger
  String get status {
    if (isOverBudget) return 'danger';
    if (isNearLimit) return 'warning';
    return 'healthy';
  }

  @override
  List<Object?> get props => [
        spentAmount,
        remainingAmount,
        percentageUsed,
        isOverBudget,
        isNearLimit,
      ];
}

/// Represents a category budget with its member contributions and spending stats
///
/// This entity aggregates:
/// - Category information (ID, name, color)
/// - Group-level budget for the category
/// - Individual member contributions (fixed or percentage-based)
/// - Spending statistics
class CategoryBudgetWithMembers extends Equatable {
  /// Category ID
  final String categoryId;

  /// Category name
  final String categoryName;

  /// Category color (for UI display)
  final int categoryColor;

  /// Budget ID for the group budget
  final String? groupBudgetId;

  /// Group budget amount for this category (in cents)
  ///
  /// This is the total budget allocated by the group for this category.
  /// Member contributions are carved out from this amount.
  final int groupBudgetAmount;

  /// List of member contributions to this category budget
  ///
  /// Each member can have either:
  /// - A fixed amount contribution
  /// - A percentage-based contribution (calculated from groupBudgetAmount)
  final List<MemberContribution> memberContributions;

  /// Spending statistics for this category
  final CategoryStats stats;

  /// Month (1-12)
  final int month;

  /// Year (e.g., 2026)
  final int year;

  const CategoryBudgetWithMembers({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.groupBudgetId,
    required this.groupBudgetAmount,
    required this.memberContributions,
    required this.stats,
    required this.month,
    required this.year,
  });

  /// Creates an empty category budget (no budget set)
  factory CategoryBudgetWithMembers.empty({
    required String categoryId,
    required String categoryName,
    required int categoryColor,
    required int month,
    required int year,
  }) {
    return CategoryBudgetWithMembers(
      categoryId: categoryId,
      categoryName: categoryName,
      categoryColor: categoryColor,
      groupBudgetId: null,
      groupBudgetAmount: 0,
      memberContributions: const [],
      stats: CategoryStats.empty(),
      month: month,
      year: year,
    );
  }

  /// Whether this category has a budget set
  bool get hasBudget => groupBudgetAmount > 0;

  /// Total member contributions (sum of all calculated amounts)
  int get totalMemberContributions {
    return memberContributions.fold(
      0,
      (sum, contribution) => sum + contribution.calculatedAmount,
    );
  }

  /// Unallocated budget (group budget minus member contributions)
  int get unallocatedBudget {
    return groupBudgetAmount - totalMemberContributions;
  }

  /// Whether all group budget is allocated to members
  bool get isFullyAllocated => unallocatedBudget <= 0;

  /// Whether member contributions exceed group budget
  bool get isOverAllocated => unallocatedBudget < 0;

  /// Number of members contributing
  int get memberCount => memberContributions.length;

  /// Percentage of group budget allocated to members
  double get allocationPercentage {
    if (groupBudgetAmount == 0) return 0.0;
    return (totalMemberContributions / groupBudgetAmount) * 100.0;
  }

  /// Creates a copy with updated fields
  CategoryBudgetWithMembers copyWith({
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    String? groupBudgetId,
    int? groupBudgetAmount,
    List<MemberContribution>? memberContributions,
    CategoryStats? stats,
    int? month,
    int? year,
  }) {
    return CategoryBudgetWithMembers(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      groupBudgetId: groupBudgetId ?? this.groupBudgetId,
      groupBudgetAmount: groupBudgetAmount ?? this.groupBudgetAmount,
      memberContributions: memberContributions ?? this.memberContributions,
      stats: stats ?? this.stats,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryColor,
        groupBudgetId,
        groupBudgetAmount,
        memberContributions,
        stats,
        month,
        year,
      ];

  @override
  String toString() {
    return 'CategoryBudgetWithMembers('
        'category: $categoryName, '
        'groupBudget: €${groupBudgetAmount / 100}, '
        'members: $memberCount, '
        'allocated: ${allocationPercentage.toStringAsFixed(1)}%, '
        'spent: €${stats.spentAmount / 100}'
        ')';
  }
}
