import 'package:equatable/equatable.dart';

/// Payment Method Entity
///
/// Represents a payment method (default or custom) available for expense tracking.
///
/// Default methods (Contanti, Carta di Credito, Bonifico, Satispay) have:
/// - isDefault = true
/// - userId = null
/// - Cannot be modified or deleted
///
/// Custom methods are user-specific:
/// - isDefault = false
/// - userId = current user's ID
/// - Can be created, updated, and deleted (with usage check)
class PaymentMethodEntity extends Equatable {
  /// Unique identifier (UUID)
  final String id;

  /// Display name (1-50 characters)
  final String name;

  /// Owner user ID (null for default methods)
  final String? userId;

  /// Whether this is a predefined default method
  final bool isDefault;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime updatedAt;

  /// Number of expenses using this method (optional, for UI display)
  final int? expenseCount;

  const PaymentMethodEntity({
    required this.id,
    required this.name,
    this.userId,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.expenseCount,
  });

  /// Factory for creating an empty instance
  factory PaymentMethodEntity.empty() {
    return PaymentMethodEntity(
      id: '',
      name: '',
      userId: null,
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      expenseCount: null,
    );
  }

  /// Create a copy with updated fields
  PaymentMethodEntity copyWith({
    String? id,
    String? name,
    String? userId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expenseCount,
  }) {
    return PaymentMethodEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseCount: expenseCount ?? this.expenseCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        userId,
        isDefault,
        createdAt,
        updatedAt,
        expenseCount,
      ];

  @override
  String toString() {
    return 'PaymentMethodEntity{id: $id, name: $name, userId: $userId, '
        'isDefault: $isDefault, expenseCount: $expenseCount}';
  }
}
