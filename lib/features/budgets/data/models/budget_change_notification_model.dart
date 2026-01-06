// Data Model: Budget Change Notification Model
// Feature: Italian Categories and Budget Management (004)

import '../../domain/entities/budget_change_notification_entity.dart';

class BudgetChangeNotificationModel extends BudgetChangeNotificationEntity {
  const BudgetChangeNotificationModel({
    required super.categoryId,
    required super.categoryName,
    required super.oldGroupBudget,
    required super.newGroupBudget,
    required super.oldPersonalBudget,
    required super.newPersonalBudget,
    required super.percentageValue,
    required super.changedAt,
  });

  /// Create BudgetChangeNotificationModel from JSON (Supabase RPC response)
  factory BudgetChangeNotificationModel.fromJson(Map<String, dynamic> json) {
    return BudgetChangeNotificationModel(
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      oldGroupBudget: json['old_group_budget'] as int,
      newGroupBudget: json['new_group_budget'] as int,
      oldPersonalBudget: json['old_personal_budget'] as int,
      newPersonalBudget: json['new_personal_budget'] as int,
      percentageValue: (json['percentage_value'] as num).toDouble(),
      changedAt: DateTime.parse(json['changed_at'] as String),
    );
  }

  /// Convert to BudgetChangeNotificationEntity
  BudgetChangeNotificationEntity toEntity() => this;

  /// Create BudgetChangeNotificationModel from BudgetChangeNotificationEntity
  factory BudgetChangeNotificationModel.fromEntity(
    BudgetChangeNotificationEntity entity,
  ) {
    return BudgetChangeNotificationModel(
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      oldGroupBudget: entity.oldGroupBudget,
      newGroupBudget: entity.newGroupBudget,
      oldPersonalBudget: entity.oldPersonalBudget,
      newPersonalBudget: entity.newPersonalBudget,
      percentageValue: entity.percentageValue,
      changedAt: entity.changedAt,
    );
  }
}
