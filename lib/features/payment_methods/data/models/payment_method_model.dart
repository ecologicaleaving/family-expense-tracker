import '../../domain/entities/payment_method_entity.dart';

/// Payment Method Model
///
/// Data transfer object for payment methods with JSON serialization support.
/// Extends PaymentMethodEntity to inherit domain logic.
class PaymentMethodModel extends PaymentMethodEntity {
  const PaymentMethodModel({
    required super.id,
    required super.name,
    super.userId,
    required super.isDefault,
    required super.createdAt,
    required super.updatedAt,
    super.expenseCount,
  });

  /// Create model from JSON (Supabase response)
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      name: json['name'] as String,
      userId: json['user_id'] as String?,
      isDefault: json['is_default'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expenseCount: _parseExpenseCount(json['expense_count']),
    );
  }

  /// Parse expense count from Supabase aggregation response
  /// Supabase returns count as [{"count": n}] when using aggregation
  static int? _parseExpenseCount(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is List && value.isNotEmpty) {
      final firstItem = value.first;
      if (firstItem is Map<String, dynamic>) {
        return firstItem['count'] as int?;
      }
    }
    return null;
  }

  /// Convert model to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Note: expense_count is read-only, not included in writes
    };
  }

  /// Create model from entity
  factory PaymentMethodModel.fromEntity(PaymentMethodEntity entity) {
    return PaymentMethodModel(
      id: entity.id,
      name: entity.name,
      userId: entity.userId,
      isDefault: entity.isDefault,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      expenseCount: entity.expenseCount,
    );
  }

  /// Convert model to entity (unnecessary since model extends entity, but useful for clarity)
  PaymentMethodEntity toEntity() {
    return PaymentMethodEntity(
      id: id,
      name: name,
      userId: userId,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
      expenseCount: expenseCount,
    );
  }

  /// Create a copy with updated fields
  @override
  PaymentMethodModel copyWith({
    String? id,
    String? name,
    String? userId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expenseCount,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseCount: expenseCount ?? this.expenseCount,
    );
  }
}
