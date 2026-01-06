// Data Model: Member Budget Contribution Model
// Feature: Italian Categories and Budget Management (004)

import '../../domain/entities/member_budget_contribution_entity.dart';

class MemberBudgetContributionModel extends MemberBudgetContributionEntity {
  const MemberBudgetContributionModel({
    required super.userId,
    required super.userName,
    required super.userEmail,
    super.percentageValue,
    super.calculatedAmount,
    super.budgetType,
  });

  /// Create MemberBudgetContributionModel from JSON (Supabase RPC response)
  factory MemberBudgetContributionModel.fromJson(Map<String, dynamic> json) {
    return MemberBudgetContributionModel(
      userId: json['user_id'] as String,
      userName: json['user_name'] as String,
      userEmail: json['user_email'] as String,
      percentageValue: json['percentage_value'] != null
          ? (json['percentage_value'] as num).toDouble()
          : null,
      calculatedAmount: json['calculated_amount'] as int?,
      budgetType: json['budget_type'] as String?,
    );
  }

  /// Convert to MemberBudgetContributionEntity
  MemberBudgetContributionEntity toEntity() => this;

  /// Create MemberBudgetContributionModel from MemberBudgetContributionEntity
  factory MemberBudgetContributionModel.fromEntity(
    MemberBudgetContributionEntity entity,
  ) {
    return MemberBudgetContributionModel(
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      percentageValue: entity.percentageValue,
      calculatedAmount: entity.calculatedAmount,
      budgetType: entity.budgetType,
    );
  }
}
