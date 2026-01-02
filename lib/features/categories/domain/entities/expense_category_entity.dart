import 'package:equatable/equatable.dart';

/// Expense category entity representing a customizable expense category.
///
/// Managed by group administrators. Default categories cannot be deleted.
class ExpenseCategoryEntity extends Equatable {
  const ExpenseCategoryEntity({
    required this.id,
    required this.name,
    required this.groupId,
    required this.isDefault,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.expenseCount,
  });

  /// Unique category identifier
  final String id;

  /// Category name (1-50 characters)
  final String name;

  /// The family group this category belongs to
  final String groupId;

  /// True for system default categories (Food, Utilities, etc.)
  final bool isDefault;

  /// User ID of who created the category (null for default categories)
  final String? createdBy;

  /// When the category was created
  final DateTime createdAt;

  /// When the category was last updated
  final DateTime updatedAt;

  /// Number of expenses using this category (optional, for display)
  final int? expenseCount;

  /// Check if this category can be deleted
  bool get canDelete => !isDefault;

  /// Check if this category can be renamed
  bool get canRename => !isDefault;

  /// Check if this category has expenses
  bool get hasExpenses => (expenseCount ?? 0) > 0;

  /// Get usage description
  String get usageDescription {
    if (expenseCount == null) return '';
    if (expenseCount == 0) return 'No expenses';
    if (expenseCount == 1) return '1 expense';
    return '$expenseCount expenses';
  }

  /// Create an empty category (for initial state)
  factory ExpenseCategoryEntity.empty() {
    return ExpenseCategoryEntity(
      id: '',
      name: '',
      groupId: '',
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Check if this is an empty category
  bool get isEmpty => id.isEmpty;

  /// Check if this is a valid category
  bool get isNotEmpty => id.isNotEmpty;

  /// Create a copy with updated fields
  ExpenseCategoryEntity copyWith({
    String? id,
    String? name,
    String? groupId,
    bool? isDefault,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? expenseCount,
  }) {
    return ExpenseCategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      isDefault: isDefault ?? this.isDefault,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expenseCount: expenseCount ?? this.expenseCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        groupId,
        isDefault,
        createdBy,
        createdAt,
        updatedAt,
        expenseCount,
      ];

  @override
  String toString() {
    return 'ExpenseCategoryEntity(id: $id, name: $name, isDefault: $isDefault, usage: $usageDescription)';
  }
}
