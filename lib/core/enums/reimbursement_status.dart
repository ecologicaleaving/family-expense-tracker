import 'package:flutter/material.dart';

/// Reimbursement status for expenses
///
/// State machine transitions:
/// - none → reimbursable (mark as pending)
/// - reimbursable → reimbursed (received money back)
/// - reimbursable → none (cancel reimbursement)
/// - reimbursed → reimbursable (undo - requires confirmation)
/// - reimbursed → none (undo - requires confirmation)
enum ReimbursementStatus {
  /// Regular expense with no reimbursement expected
  none('none', 'Nessun rimborso'),

  /// Expense awaiting reimbursement
  reimbursable('reimbursable', 'Da rimborsare'),

  /// Expense that has been reimbursed
  reimbursed('reimbursed', 'Rimborsato');

  const ReimbursementStatus(this.value, this.label);

  /// Database value (stored in Supabase/Drift)
  final String value;

  /// Human-readable Italian label for UI display
  final String label;

  /// Parse from database string value
  static ReimbursementStatus fromString(String value) {
    return ReimbursementStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReimbursementStatus.none,
    );
  }

  /// Get icon for this status
  IconData get icon {
    switch (this) {
      case ReimbursementStatus.none:
        return Icons.check_circle_outline;
      case ReimbursementStatus.reimbursable:
        return Icons.schedule;
      case ReimbursementStatus.reimbursed:
        return Icons.check_circle;
    }
  }

  /// Get color for this status (using Material 3 palette)
  Color getColor(ColorScheme colorScheme) {
    switch (this) {
      case ReimbursementStatus.none:
        return colorScheme.onSurface;
      case ReimbursementStatus.reimbursable:
        return colorScheme.tertiary; // Amber/Honey color
      case ReimbursementStatus.reimbursed:
        return colorScheme.primary; // Sage Green
    }
  }
}
