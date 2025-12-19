import '../../../../core/config/constants.dart';
import '../../domain/entities/expense_entity.dart';

/// Expense model for JSON serialization/deserialization.
///
/// Maps to the 'expenses' table in Supabase.
class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.groupId,
    required super.createdBy,
    required super.amount,
    required super.date,
    required super.category,
    super.merchant,
    super.notes,
    super.receiptUrl,
    super.createdByName,
    super.createdAt,
    super.updatedAt,
  });

  /// Create an ExpenseModel from a JSON map (expenses table row).
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      createdBy: json['created_by'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      category: ExpenseCategory.fromValue(json['category'] as String),
      merchant: json['merchant'] as String?,
      notes: json['notes'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON map for database operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'created_by': createdBy,
      'amount': amount,
      'date': date.toIso8601String().split('T')[0],
      'category': category.value,
      'merchant': merchant,
      'notes': notes,
      'receipt_url': receiptUrl,
      'created_by_name': createdByName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create an ExpenseModel from an ExpenseEntity.
  factory ExpenseModel.fromEntity(ExpenseEntity entity) {
    return ExpenseModel(
      id: entity.id,
      groupId: entity.groupId,
      createdBy: entity.createdBy,
      amount: entity.amount,
      date: entity.date,
      category: entity.category,
      merchant: entity.merchant,
      notes: entity.notes,
      receiptUrl: entity.receiptUrl,
      createdByName: entity.createdByName,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to ExpenseEntity.
  ExpenseEntity toEntity() {
    return ExpenseEntity(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      amount: amount,
      date: date,
      category: category,
      merchant: merchant,
      notes: notes,
      receiptUrl: receiptUrl,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create a copy with updated fields.
  @override
  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? createdBy,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    String? merchant,
    String? notes,
    String? receiptUrl,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
