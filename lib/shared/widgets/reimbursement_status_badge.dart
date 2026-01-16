import 'package:flutter/material.dart';
import '../../core/enums/reimbursement_status.dart';

/// Badge widget for displaying reimbursement status of an expense
///
/// Feature 012-expense-improvements - User Story 3 (T031)
///
/// Displays a visual indicator for expenses that are:
/// - Awaiting reimbursement (reimbursable)
/// - Already reimbursed (reimbursed)
/// - Regular expenses (none) - hidden by default
///
/// Supports two display modes:
/// - **Compact**: Icon only (for list items)
/// - **Full**: Icon + Label (for detail screens)
class ReimbursementStatusBadge extends StatelessWidget {
  const ReimbursementStatusBadge({
    super.key,
    required this.status,
    this.mode = ReimbursementBadgeMode.compact,
  });

  /// Reimbursement status to display
  final ReimbursementStatus status;

  /// Display mode (compact or full)
  final ReimbursementBadgeMode mode;

  @override
  Widget build(BuildContext context) {
    // Don't show badge for regular expenses (none status)
    if (status == ReimbursementStatus.none) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get color and icon from the enum
    final color = status.getColor(colorScheme);
    final icon = status.icon;
    final label = status.label;

    if (mode == ReimbursementBadgeMode.compact) {
      // Compact mode: Icon only with background
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      );
    } else {
      // Full mode: Icon + Label
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Display mode for reimbursement status badge
enum ReimbursementBadgeMode {
  /// Compact mode: Icon only (for list items)
  compact,

  /// Full mode: Icon + Label (for detail screens)
  full,
}
