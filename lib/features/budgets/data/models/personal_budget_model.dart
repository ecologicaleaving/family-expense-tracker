import '../../domain/entities/personal_budget_entity.dart';

/// Personal budget model for JSON serialization/deserialization.
///
/// Maps to the 'personal_budgets' table in Supabase.
class PersonalBudgetModel extends PersonalBudgetEntity {
  const PersonalBudgetModel({
    required super.id,
    required super.userId,
    required super.amount,
    required super.month,
    required super.year,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create a PersonalBudgetModel from a JSON map (personal_budgets table row).
  factory PersonalBudgetModel.fromJson(Map<String, dynamic> json) {
    return PersonalBudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON map for database operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'month': month,
      'year': year,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a PersonalBudgetModel from a PersonalBudgetEntity.
  factory PersonalBudgetModel.fromEntity(PersonalBudgetEntity entity) {
    return PersonalBudgetModel(
      id: entity.id,
      userId: entity.userId,
      amount: entity.amount,
      month: entity.month,
      year: entity.year,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to PersonalBudgetEntity.
  PersonalBudgetEntity toEntity() {
    return PersonalBudgetEntity(
      id: id,
      userId: userId,
      amount: amount,
      month: month,
      year: year,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create a copy with updated fields.
  @override
  PersonalBudgetModel copyWith({
    String? id,
    String? userId,
    int? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonalBudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
