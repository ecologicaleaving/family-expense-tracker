/// Types of budget validation issues
enum IssueType {
  /// Category budgets sum exceeds group budget
  overAllocation,

  /// Member percentages in a category exceed 100%
  percentageOverflow,

  /// A percentage value is outside 0-100 range
  invalidPercentage,

  /// Group budget is not set
  missingGroupBudget,

  /// Category budget is not set
  missingCategoryBudget,

  /// Budget amount is invalid (negative, zero, or too large)
  invalidAmount,

  /// Other validation issue
  other,
}

/// Severity levels for validation issues
enum Severity {
  /// Critical error that must be fixed
  error,

  /// Warning that should be addressed
  warning,

  /// Informational message
  info,
}

/// Represents a budget validation issue
///
/// Used by BudgetValidator to report problems with budget configuration.
class BudgetValidationIssue {
  /// Type of validation issue
  final IssueType type;

  /// Severity level
  final Severity severity;

  /// Human-readable message describing the issue
  final String message;

  /// Optional category ID related to this issue
  final String? categoryId;

  /// Optional user ID related to this issue
  final String? userId;

  const BudgetValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    this.categoryId,
    this.userId,
  });

  /// Creates an over-allocation error
  factory BudgetValidationIssue.overAllocation({
    required int categoryTotal,
    required int groupBudget,
  }) {
    return BudgetValidationIssue(
      type: IssueType.overAllocation,
      severity: Severity.error,
      message:
          'Somma budget categorie (€${categoryTotal ~/ 100}) supera budget gruppo (€${groupBudget ~/ 100})',
    );
  }

  /// Creates a percentage overflow warning
  factory BudgetValidationIssue.percentageOverflow({
    required String categoryName,
    required String categoryId,
    required double totalPercentage,
  }) {
    return BudgetValidationIssue(
      type: IssueType.percentageOverflow,
      severity: Severity.warning,
      message:
          'Categoria "$categoryName": somma percentuali = ${totalPercentage.toStringAsFixed(1)}% > 100%',
      categoryId: categoryId,
    );
  }

  /// Creates an invalid percentage error
  factory BudgetValidationIssue.invalidPercentage({
    required String userName,
    required String categoryId,
    required String userId,
    required double percentage,
  }) {
    return BudgetValidationIssue(
      type: IssueType.invalidPercentage,
      severity: Severity.error,
      message:
          '$userName: percentuale ${percentage.toStringAsFixed(1)}% non valida (deve essere 0-100)',
      categoryId: categoryId,
      userId: userId,
    );
  }

  /// Creates a missing group budget error
  factory BudgetValidationIssue.missingGroupBudget() {
    return const BudgetValidationIssue(
      type: IssueType.missingGroupBudget,
      severity: Severity.error,
      message: 'Budget gruppo non impostato',
    );
  }

  /// Creates a missing category budget warning
  factory BudgetValidationIssue.missingCategoryBudget({
    required String categoryName,
    required String categoryId,
  }) {
    return BudgetValidationIssue(
      type: IssueType.missingCategoryBudget,
      severity: Severity.warning,
      message: 'Categoria "$categoryName": budget non impostato',
      categoryId: categoryId,
    );
  }

  /// Creates an invalid amount error
  factory BudgetValidationIssue.invalidAmount({
    required String context,
    required int amount,
  }) {
    return BudgetValidationIssue(
      type: IssueType.invalidAmount,
      severity: Severity.error,
      message: '$context: importo non valido (€${amount ~/ 100})',
    );
  }

  /// Whether this is an error (blocks operations)
  bool get isError => severity == Severity.error;

  /// Whether this is a warning (can proceed but should fix)
  bool get isWarning => severity == Severity.warning;

  /// Whether this is informational
  bool get isInfo => severity == Severity.info;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetValidationIssue &&
        other.type == type &&
        other.severity == severity &&
        other.message == message &&
        other.categoryId == categoryId &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      severity,
      message,
      categoryId,
      userId,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('[${severity.name.toUpperCase()}] $message');
    if (categoryId != null || userId != null) {
      buffer.write(' (');
      if (categoryId != null) buffer.write('category: $categoryId');
      if (categoryId != null && userId != null) buffer.write(', ');
      if (userId != null) buffer.write('user: $userId');
      buffer.write(')');
    }
    return buffer.toString();
  }
}
