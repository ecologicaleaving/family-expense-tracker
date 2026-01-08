import 'package:equatable/equatable.dart';

import 'category_budget_with_members_entity.dart';

/// Virtual category representing all group expenses in personal budget view
///
/// This category does NOT exist in the database. It is computed on-demand to show
/// a user their total group expense contributions in their personal budget view.
///
/// Budget = SUM of user's contributions across all group categories
/// Spent = SUM of group expenses created by this user
///
/// This category appears ONLY in personal budget view, not in group budget view.
class VirtualGroupExpensesCategory extends Equatable {
  /// Virtual category ID (not in database)
  static const String virtualCategoryId = 'virtual_group_expenses';

  /// Display name in Italian
  static const String displayName = 'Spese di Gruppo';

  /// Icon for display
  static const String icon = 'group';

  /// Color (orange to match group theme)
  static const String color = '#FF6B35';

  /// Budget amount in cents (SUM of user's contributions in group categories)
  final int budgetAmount;

  /// Spent amount in cents (SUM of group expenses created by user)
  final int spentAmount;

  /// Remaining budget in cents
  final int remainingAmount;

  /// Percentage of budget used (0-100+)
  final double percentageUsed;

  /// Breakdown by real category
  /// Map<categoryId, CategoryContribution>
  final Map<String, CategoryContribution> categoryBreakdown;

  /// User ID (whose personal budget this belongs to)
  final String userId;

  /// Group ID
  final String groupId;

  /// Month (1-12)
  final int month;

  /// Year (e.g., 2026)
  final int year;

  const VirtualGroupExpensesCategory({
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
    required this.categoryBreakdown,
    required this.userId,
    required this.groupId,
    required this.month,
    required this.year,
  });

  /// Creates empty virtual category (no contributions)
  factory VirtualGroupExpensesCategory.empty({
    required String userId,
    required String groupId,
    required int month,
    required int year,
  }) {
    return VirtualGroupExpensesCategory(
      budgetAmount: 0,
      spentAmount: 0,
      remainingAmount: 0,
      percentageUsed: 0.0,
      categoryBreakdown: const {},
      userId: userId,
      groupId: groupId,
      month: month,
      year: year,
    );
  }

  /// Whether user has any group contributions
  bool get hasContributions => budgetAmount > 0;

  /// Whether user has overspent their group budget
  bool get isOverBudget => hasContributions && spentAmount > budgetAmount;

  /// Whether user is near limit (>= 80% spent)
  bool get isNearLimit => hasContributions && percentageUsed >= 80.0;

  /// Status: 'healthy', 'warning', or 'danger'
  String get status {
    if (!hasContributions) return 'healthy';
    if (isOverBudget) return 'danger';
    if (isNearLimit) return 'warning';
    return 'healthy';
  }

  /// Formatted budget (in euros)
  String get formattedBudget => '€${(budgetAmount / 100).toStringAsFixed(2)}';

  /// Formatted spent (in euros)
  String get formattedSpent => '€${(spentAmount / 100).toStringAsFixed(2)}';

  /// Formatted remaining (in euros)
  String get formattedRemaining => '€${(remainingAmount / 100).toStringAsFixed(2)}';

  /// Number of categories with contributions
  int get categoryCount => categoryBreakdown.length;

  @override
  List<Object?> get props => [
        budgetAmount,
        spentAmount,
        remainingAmount,
        percentageUsed,
        categoryBreakdown,
        userId,
        groupId,
        month,
        year,
      ];

  @override
  String toString() {
    return 'VirtualGroupExpensesCategory('
        'budget: €${budgetAmount / 100}, '
        'spent: €${spentAmount / 100}, '
        'categories: $categoryCount, '
        'status: $status'
        ')';
  }
}

/// Contribution to a single category within the virtual group expenses category
class CategoryContribution extends Equatable {
  /// Real category ID
  final String categoryId;

  /// Category name
  final String categoryName;

  /// Category icon
  final String categoryIcon;

  /// Category color
  final String categoryColor;

  /// User's budget contribution for this category (in cents)
  final int budgetContribution;

  /// User's spending in this category (in cents)
  final int spentAmount;

  /// Remaining budget for this category (in cents)
  final int remainingAmount;

  /// Percentage used (0-100+)
  final double percentageUsed;

  const CategoryContribution({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.budgetContribution,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentageUsed,
  });

  /// Formatted budget contribution (in euros)
  String get formattedContribution => '€${(budgetContribution / 100).toStringAsFixed(2)}';

  /// Formatted spent (in euros)
  String get formattedSpent => '€${(spentAmount / 100).toStringAsFixed(2)}';

  /// Whether over budget for this category
  bool get isOverBudget => spentAmount > budgetContribution;

  /// Whether near limit for this category
  bool get isNearLimit => percentageUsed >= 80.0;

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryIcon,
        categoryColor,
        budgetContribution,
        spentAmount,
        remainingAmount,
        percentageUsed,
      ];
}
