import 'dart:typed_data';

import 'package:dartz/dartz.dart';

import '../../../../core/enums/reimbursement_status.dart';
import '../../../../core/errors/failures.dart';
import '../entities/expense_entity.dart';

/// Abstract expense repository interface.
///
/// Defines the contract for expense operations.
/// Implementations should handle the actual communication with
/// the backend (Supabase).
abstract class ExpenseRepository {
  /// Get all expenses for the current user's group.
  ///
  /// Optionally filter by date range, category, expense type, and reimbursement status.
  Future<Either<Failure, List<ExpenseEntity>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? createdBy,
    bool? isGroupExpense,
    ReimbursementStatus? reimbursementStatus, // T047
    int? limit,
    int? offset,
  });

  /// Get a single expense by ID.
  Future<Either<Failure, ExpenseEntity>> getExpense({
    required String expenseId,
  });

  /// Create a new expense.
  ///
  /// Returns the created expense with its generated ID.
  /// If paymentMethodId is null, defaults to "Contanti" (Cash).
  Future<Either<Failure, ExpenseEntity>> createExpense({
    required double amount,
    required DateTime date,
    required String categoryId,
    String? paymentMethodId, // Defaults to "Contanti" if null
    String? merchant,
    String? notes,
    Uint8List? receiptImage,
    bool isGroupExpense = true,
    ReimbursementStatus reimbursementStatus = ReimbursementStatus.none, // T047
  });

  /// Update an existing expense.
  Future<Either<Failure, ExpenseEntity>> updateExpense({
    required String expenseId,
    double? amount,
    DateTime? date,
    String? categoryId,
    String? paymentMethodId,
    String? merchant,
    String? notes,
    ReimbursementStatus? reimbursementStatus, // T047
  });

  /// Delete an expense.
  Future<Either<Failure, Unit>> deleteExpense({
    required String expenseId,
  });

  /// Update expense classification (group or personal).
  ///
  /// Changes the `is_group_expense` field. This affects:
  /// - Visibility: Personal expenses only visible to creator
  /// - Budget allocation: Which budgets the expense counts toward
  Future<Either<Failure, ExpenseEntity>> updateExpenseClassification({
    required String expenseId,
    required bool isGroupExpense,
  });

  /// Upload a receipt image and return the URL.
  Future<Either<Failure, String>> uploadReceiptImage({
    required String expenseId,
    required Uint8List imageData,
  });

  /// Get a signed URL for viewing a receipt.
  Future<Either<Failure, String>> getReceiptUrl({
    required String receiptPath,
  });

  /// Get expenses summary for a date range.
  Future<Either<Failure, ExpensesSummary>> getExpensesSummary({
    DateTime? startDate,
    DateTime? endDate,
  });
}

/// Summary of expenses for a period.
class ExpensesSummary {
  const ExpensesSummary({
    required this.totalAmount,
    required this.expenseCount,
    required this.byCategory,
    required this.byMember,
  });

  /// Total amount of all expenses
  final double totalAmount;

  /// Number of expenses
  final int expenseCount;

  /// Breakdown by category
  final Map<String, double> byCategory;

  /// Breakdown by member
  final Map<String, MemberExpenses> byMember;
}

/// Expenses breakdown for a single member.
class MemberExpenses {
  const MemberExpenses({
    required this.userId,
    required this.displayName,
    required this.totalAmount,
    required this.expenseCount,
  });

  final String userId;
  final String displayName;
  final double totalAmount;
  final int expenseCount;
}
