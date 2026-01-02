import 'package:equatable/equatable.dart';

import '../../../../core/config/constants.dart';

/// Expense entity representing a household expense.
class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.amount,
    required this.date,
    required this.category,
    this.isGroupExpense = true,
    this.merchant,
    this.notes,
    this.receiptUrl,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique expense identifier
  final String id;

  /// The family group this expense belongs to
  final String groupId;

  /// User ID of who created the expense
  final String createdBy;

  /// Expense amount in EUR
  final double amount;

  /// Date of the expense
  final DateTime date;

  /// Expense category
  final ExpenseCategory category;

  /// Expense classification: true for group expenses (visible to all), false for personal (visible only to creator)
  final bool isGroupExpense;

  /// Merchant/store name (optional)
  final String? merchant;

  /// Additional notes (optional)
  final String? notes;

  /// URL to receipt image in storage (optional)
  final String? receiptUrl;

  /// Display name of who created the expense (for display purposes)
  final String? createdByName;

  /// When the expense was created
  final DateTime? createdAt;

  /// When the expense was last updated
  final DateTime? updatedAt;

  /// Check if the user can edit this expense
  bool canEdit(String userId, bool isAdmin) {
    return createdBy == userId || isAdmin;
  }

  /// Check if the user can delete this expense
  bool canDelete(String userId, bool isAdmin) {
    return createdBy == userId || isAdmin;
  }

  /// Get formatted amount string
  String get formattedAmount => '€${amount.toStringAsFixed(2)}';

  /// Check if this expense has a receipt attached
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  /// Create an empty expense (for initial state)
  factory ExpenseEntity.empty() {
    return ExpenseEntity(
      id: '',
      groupId: '',
      createdBy: '',
      amount: 0,
      date: DateTime.now(),
      category: ExpenseCategory.altro,
    );
  }

  /// Check if this is an empty expense
  bool get isEmpty => id.isEmpty;

  /// Check if this is a valid expense
  bool get isNotEmpty => id.isNotEmpty;

  /// Create a copy with updated fields
  ExpenseEntity copyWith({
    String? id,
    String? groupId,
    String? createdBy,
    double? amount,
    DateTime? date,
    ExpenseCategory? category,
    bool? isGroupExpense,
    String? merchant,
    String? notes,
    String? receiptUrl,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdBy: createdBy ?? this.createdBy,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      isGroupExpense: isGroupExpense ?? this.isGroupExpense,
      merchant: merchant ?? this.merchant,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        createdBy,
        amount,
        date,
        category,
        isGroupExpense,
        merchant,
        notes,
        receiptUrl,
        createdByName,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ExpenseEntity(id: $id, amount: $formattedAmount, merchant: $merchant, category: ${category.label})';
  }
}
