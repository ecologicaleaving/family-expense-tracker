// Domain Entity: Budget Percentage History for tracking percentage changes
// Feature: Italian Categories and Budget Management (004)

import 'package:equatable/equatable.dart';

class BudgetPercentageHistoryEntity extends Equatable {
  final String id;
  final String categoryBudgetId;
  final String userId;
  final String categoryId;
  final String groupId;
  final int year;
  final int month;
  final double percentageValue; // 0-100
  final int groupBudgetAmount; // Historical group budget amount in cents
  final int calculatedAmount; // Historical calculated amount in cents
  final DateTime changedAt;
  final String changedBy; // Profile ID who made the change
  final DateTime createdAt;

  const BudgetPercentageHistoryEntity({
    required this.id,
    required this.categoryBudgetId,
    required this.userId,
    required this.categoryId,
    required this.groupId,
    required this.year,
    required this.month,
    required this.percentageValue,
    required this.groupBudgetAmount,
    required this.calculatedAmount,
    required this.changedAt,
    required this.changedBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        categoryBudgetId,
        userId,
        categoryId,
        groupId,
        year,
        month,
        percentageValue,
        groupBudgetAmount,
        calculatedAmount,
        changedAt,
        changedBy,
        createdAt,
      ];

  @override
  bool? get stringify => true;
}
