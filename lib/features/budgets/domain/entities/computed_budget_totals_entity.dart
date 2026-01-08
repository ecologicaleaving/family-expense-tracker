import 'package:equatable/equatable.dart';

/// Computed budget totals calculated from category budgets
///
/// This entity replaces the manual GroupBudgetEntity and PersonalBudgetEntity
/// with totals calculated from category budgets and member contributions.
///
/// - Group budget total = SUM of all category budget amounts
/// - Personal budget total = SUM of user's contributions across categories
class ComputedBudgetTotals extends Equatable {
  /// Total group budget in cents (SUM of all category budgets)
  final int totalGroupBudget;

  /// Total personal budget in cents (SUM of user's contributions + personal categories)
  final int totalPersonalBudget;

  /// Breakdown by category ID → budget amount in cents
  final Map<String, int> categoryBreakdown;

  /// Breakdown by member ID → total contribution in cents
  final Map<String, int> memberBreakdown;

  /// Group ID
  final String groupId;

  /// User ID (for personal budget calculation)
  final String userId;

  /// Month (1-12)
  final int month;

  /// Year (e.g., 2026)
  final int year;

  /// Number of categories with budgets
  final int categoryCount;

  /// Number of member contributions
  final int contributionCount;

  const ComputedBudgetTotals({
    required this.totalGroupBudget,
    required this.totalPersonalBudget,
    required this.categoryBreakdown,
    required this.memberBreakdown,
    required this.groupId,
    required this.userId,
    required this.month,
    required this.year,
    required this.categoryCount,
    required this.contributionCount,
  });

  /// Creates empty totals (no budgets)
  factory ComputedBudgetTotals.empty({
    required String groupId,
    required String userId,
    required int month,
    required int year,
  }) {
    return ComputedBudgetTotals(
      totalGroupBudget: 0,
      totalPersonalBudget: 0,
      categoryBreakdown: const {},
      memberBreakdown: const {},
      groupId: groupId,
      userId: userId,
      month: month,
      year: year,
      categoryCount: 0,
      contributionCount: 0,
    );
  }

  /// Whether any group budgets are set
  bool get hasGroupBudgets => totalGroupBudget > 0;

  /// Whether any personal budgets are set
  bool get hasPersonalBudgets => totalPersonalBudget > 0;

  /// Formatted group budget (in euros)
  String get formattedGroupBudget => '€${(totalGroupBudget / 100).toStringAsFixed(2)}';

  /// Formatted personal budget (in euros)
  String get formattedPersonalBudget => '€${(totalPersonalBudget / 100).toStringAsFixed(2)}';

  /// Whether this user has any contributions to group budgets
  bool get hasContributions => contributionCount > 0;

  /// Creates a copy with updated fields
  ComputedBudgetTotals copyWith({
    int? totalGroupBudget,
    int? totalPersonalBudget,
    Map<String, int>? categoryBreakdown,
    Map<String, int>? memberBreakdown,
    String? groupId,
    String? userId,
    int? month,
    int? year,
    int? categoryCount,
    int? contributionCount,
  }) {
    return ComputedBudgetTotals(
      totalGroupBudget: totalGroupBudget ?? this.totalGroupBudget,
      totalPersonalBudget: totalPersonalBudget ?? this.totalPersonalBudget,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      memberBreakdown: memberBreakdown ?? this.memberBreakdown,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      year: year ?? this.year,
      categoryCount: categoryCount ?? this.categoryCount,
      contributionCount: contributionCount ?? this.contributionCount,
    );
  }

  @override
  List<Object?> get props => [
        totalGroupBudget,
        totalPersonalBudget,
        categoryBreakdown,
        memberBreakdown,
        groupId,
        userId,
        month,
        year,
        categoryCount,
        contributionCount,
      ];

  @override
  String toString() {
    return 'ComputedBudgetTotals('
        'group: €${totalGroupBudget / 100}, '
        'personal: €${totalPersonalBudget / 100}, '
        'categories: $categoryCount, '
        'contributions: $contributionCount'
        ')';
  }
}
