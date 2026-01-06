// Domain Entity: Category Budget for monthly budget allocations
// Feature: Italian Categories and Budget Management (004)
// Task: T014, Extended for percentage budgets

import 'package:equatable/equatable.dart';

import '../../../../core/enums/budget_type.dart';

class CategoryBudgetEntity extends Equatable {
  final String id;
  final String categoryId;
  final String groupId;
  final int amount; // Budget amount in cents (EUR) - for FIXED type or fallback
  final int month; // 1-12
  final int year; // e.g., 2026
  final String createdBy; // Profile ID of creator
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields for percentage budgets (Feature 004 extension)
  final bool isGroupBudget; // true = group budget, false = personal budget
  final BudgetType budgetType; // FIXED or PERCENTAGE
  final double? percentageOfGroup; // Percentage (0-100) for PERCENTAGE type
  final String? userId; // User ID for personal budgets (null for group budgets)
  final int? calculatedAmount; // Auto-calculated amount for PERCENTAGE type

  const CategoryBudgetEntity({
    required this.id,
    required this.categoryId,
    required this.groupId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isGroupBudget = true,
    this.budgetType = BudgetType.fixed,
    this.percentageOfGroup,
    this.userId,
    this.calculatedAmount,
  });

  /// Get the effective budget amount to use
  /// For PERCENTAGE budgets, uses calculatedAmount; for FIXED, uses amount
  int get effectiveBudget => budgetType.isPercentage
      ? (calculatedAmount ?? amount)
      : amount;

  /// Whether this is a personal budget
  bool get isPersonalBudget => !isGroupBudget;

  @override
  List<Object?> get props => [
        id,
        categoryId,
        groupId,
        amount,
        month,
        year,
        createdBy,
        createdAt,
        updatedAt,
        isGroupBudget,
        budgetType,
        percentageOfGroup,
        userId,
        calculatedAmount,
      ];

  @override
  bool? get stringify => true;
}
