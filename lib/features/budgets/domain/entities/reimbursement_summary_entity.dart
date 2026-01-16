import 'package:equatable/equatable.dart';

/// Summary of reimbursement-related amounts across expenses.
///
/// Computed on-demand from expense data, not stored in database.
/// Feature 012-expense-improvements (T013)
class ReimbursementSummaryEntity extends Equatable {
  const ReimbursementSummaryEntity({
    required this.totalPendingReimbursements,
    required this.totalReimbursedIncome,
    required this.pendingExpenseCount,
    required this.reimbursedExpenseCount,
  });

  /// Total amount of expenses marked as reimbursable (pending reimbursement) in cents
  final int totalPendingReimbursements;

  /// Total amount of expenses marked as reimbursed in the current period in cents
  final int totalReimbursedIncome;

  /// Number of expenses pending reimbursement
  final int pendingExpenseCount;

  /// Number of expenses that have been reimbursed in the current period
  final int reimbursedExpenseCount;

  /// Check if there are any pending reimbursements
  bool get hasPendingReimbursements => totalPendingReimbursements > 0;

  /// Check if there are any reimbursed expenses
  bool get hasReimbursedIncome => totalReimbursedIncome > 0;

  /// Get formatted pending amount string
  String get formattedPendingAmount {
    final euros = totalPendingReimbursements / 100;
    return '€${euros.toStringAsFixed(2)}';
  }

  /// Get formatted reimbursed amount string
  String get formattedReimbursedAmount {
    final euros = totalReimbursedIncome / 100;
    return '€${euros.toStringAsFixed(2)}';
  }

  /// Create empty summary (no reimbursements)
  factory ReimbursementSummaryEntity.empty() {
    return const ReimbursementSummaryEntity(
      totalPendingReimbursements: 0,
      totalReimbursedIncome: 0,
      pendingExpenseCount: 0,
      reimbursedExpenseCount: 0,
    );
  }

  /// Create a copy with updated fields
  ReimbursementSummaryEntity copyWith({
    int? totalPendingReimbursements,
    int? totalReimbursedIncome,
    int? pendingExpenseCount,
    int? reimbursedExpenseCount,
  }) {
    return ReimbursementSummaryEntity(
      totalPendingReimbursements:
          totalPendingReimbursements ?? this.totalPendingReimbursements,
      totalReimbursedIncome:
          totalReimbursedIncome ?? this.totalReimbursedIncome,
      pendingExpenseCount: pendingExpenseCount ?? this.pendingExpenseCount,
      reimbursedExpenseCount:
          reimbursedExpenseCount ?? this.reimbursedExpenseCount,
    );
  }

  @override
  List<Object?> get props => [
        totalPendingReimbursements,
        totalReimbursedIncome,
        pendingExpenseCount,
        reimbursedExpenseCount,
      ];

  @override
  String toString() {
    return 'ReimbursementSummaryEntity(pending: $formattedPendingAmount ($pendingExpenseCount), reimbursed: $formattedReimbursedAmount ($reimbursedExpenseCount))';
  }
}
