// Domain Entity: Member Budget Contribution for showing who contributes percentages
// Feature: Italian Categories and Budget Management (004)

import 'package:equatable/equatable.dart';

class MemberBudgetContributionEntity extends Equatable {
  final String userId;
  final String userName;
  final String userEmail;
  final double? percentageValue; // null if member has no percentage budget
  final int? calculatedAmount; // null if member has no percentage budget
  final String? budgetType; // 'FIXED', 'PERCENTAGE', or null

  const MemberBudgetContributionEntity({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.percentageValue,
    this.calculatedAmount,
    this.budgetType,
  });

  /// Whether this member has a percentage budget set
  bool get hasPercentageBudget => percentageValue != null && budgetType == 'PERCENTAGE';

  @override
  List<Object?> get props => [
        userId,
        userName,
        userEmail,
        percentageValue,
        calculatedAmount,
        budgetType,
      ];

  @override
  bool? get stringify => true;
}
