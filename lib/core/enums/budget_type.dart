// Budget Type Enum
// Feature: Italian Categories and Budget Management (004)

/// Type of budget - either fixed amount or percentage of group budget
enum BudgetType {
  /// Fixed euro amount budget
  fixed('FIXED'),

  /// Percentage-based budget calculated from group budget
  percentage('PERCENTAGE');

  const BudgetType(this.value);

  /// Database string value
  final String value;

  /// Whether this is a fixed budget
  bool get isFixed => this == BudgetType.fixed;

  /// Whether this is a percentage budget
  bool get isPercentage => this == BudgetType.percentage;

  /// Create BudgetType from string value
  static BudgetType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FIXED':
        return BudgetType.fixed;
      case 'PERCENTAGE':
        return BudgetType.percentage;
      default:
        throw ArgumentError('Invalid budget type: $value');
    }
  }

  @override
  String toString() => value;
}
