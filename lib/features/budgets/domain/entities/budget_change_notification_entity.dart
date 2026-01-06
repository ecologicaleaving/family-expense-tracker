// Domain Entity: Budget Change Notification for alerting users about budget changes
// Feature: Italian Categories and Budget Management (004)

import 'package:equatable/equatable.dart';

class BudgetChangeNotificationEntity extends Equatable {
  final String categoryId;
  final String categoryName;
  final int oldGroupBudget; // Previous group budget in cents
  final int newGroupBudget; // Current group budget in cents
  final int oldPersonalBudget; // Previous calculated personal budget in cents
  final int newPersonalBudget; // Current calculated personal budget in cents
  final double percentageValue; // User's percentage (0-100)
  final DateTime changedAt; // When the change occurred

  const BudgetChangeNotificationEntity({
    required this.categoryId,
    required this.categoryName,
    required this.oldGroupBudget,
    required this.newGroupBudget,
    required this.oldPersonalBudget,
    required this.newPersonalBudget,
    required this.percentageValue,
    required this.changedAt,
  });

  /// Calculate the change amount in cents
  int get budgetChangeAmount => newPersonalBudget - oldPersonalBudget;

  /// Whether the budget increased
  bool get isIncrease => budgetChangeAmount > 0;

  /// Whether the budget decreased
  bool get isDecrease => budgetChangeAmount < 0;

  /// Formatted old group budget in euros
  String get formattedOldGroupBudget => '€${(oldGroupBudget / 100).toStringAsFixed(2)}';

  /// Formatted new group budget in euros
  String get formattedNewGroupBudget => '€${(newGroupBudget / 100).toStringAsFixed(2)}';

  /// Formatted old personal budget in euros
  String get formattedOldPersonalBudget => '€${(oldPersonalBudget / 100).toStringAsFixed(2)}';

  /// Formatted new personal budget in euros
  String get formattedNewPersonalBudget => '€${(newPersonalBudget / 100).toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        oldGroupBudget,
        newGroupBudget,
        oldPersonalBudget,
        newPersonalBudget,
        percentageValue,
        changedAt,
      ];

  @override
  bool? get stringify => true;
}
