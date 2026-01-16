import 'package:flutter/material.dart';
import '../../../../core/enums/reimbursement_status.dart';

/// Dialog for confirming reimbursement status changes
///
/// Feature 012-expense-improvements - User Story 3 (T033)
///
/// Shows a confirmation dialog when changing reimbursement status,
/// with special warnings for reversions from "reimbursed" state.
///
/// This is important because:
/// - Marking as reimbursed affects budget calculations
/// - Reverting from reimbursed state needs explicit confirmation
/// - Users should understand the impact of status changes
class ReimbursementStatusChangeDialog extends StatelessWidget {
  const ReimbursementStatusChangeDialog({
    super.key,
    required this.expenseName,
    required this.currentStatus,
    required this.newStatus,
  });

  /// Name/description of the expense being modified
  final String expenseName;

  /// Current reimbursement status
  final ReimbursementStatus currentStatus;

  /// New reimbursement status to apply
  final ReimbursementStatus newStatus;

  /// Show the confirmation dialog
  ///
  /// Returns `true` if user confirmed the change, `false` if cancelled
  static Future<bool?> show(
    BuildContext context, {
    required String expenseName,
    required ReimbursementStatus currentStatus,
    required ReimbursementStatus newStatus,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ReimbursementStatusChangeDialog(
        expenseName: expenseName,
        currentStatus: currentStatus,
        newStatus: newStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if this is a reversion from reimbursed state (requires special warning)
    final isReversion = currentStatus == ReimbursementStatus.reimbursed;

    // Build appropriate title and message
    final String title;
    final String message;
    final IconData icon;
    final Color iconColor;

    if (isReversion) {
      // Reverting from reimbursed - warning
      title = 'Modificare stato rimborso?';
      message = _getReversionMessage();
      icon = Icons.warning_rounded;
      iconColor = colorScheme.error;
    } else {
      // Normal status change - confirmation
      title = 'Conferma modifica';
      message = _getNormalMessage();
      icon = Icons.info_outline;
      iconColor = colorScheme.primary;
    }

    return AlertDialog(
      icon: Icon(
        icon,
        color: iconColor,
        size: 32,
      ),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spesa: $expenseName',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          if (isReversion) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Questa azione modificherà i calcoli del budget corrente.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isReversion
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: const Text('Conferma'),
        ),
      ],
    );
  }

  /// Get message for reversion from reimbursed state
  String _getReversionMessage() {
    switch (newStatus) {
      case ReimbursementStatus.none:
        return 'Stai per rimuovere lo stato di rimborso da questa spesa. '
            'Il budget tornerà a considerarla come spesa normale.';
      case ReimbursementStatus.reimbursable:
        return 'Stai per contrassegnare questa spesa come "da rimborsare" invece di "rimborsata". '
            'Il budget non considererà più questa spesa come rimborsata.';
      case ReimbursementStatus.reimbursed:
        return ''; // Should not happen
    }
  }

  /// Get message for normal status change
  String _getNormalMessage() {
    switch (newStatus) {
      case ReimbursementStatus.none:
        return 'Rimuovere lo stato di rimborso da questa spesa?';
      case ReimbursementStatus.reimbursable:
        return 'Contrassegnare questa spesa come da rimborsare? '
            'Potrai tracciarla finché non ricevi il rimborso.';
      case ReimbursementStatus.reimbursed:
        return 'Confermare che hai ricevuto il rimborso per questa spesa? '
            'L\'importo verrà aggiunto al budget disponibile per questo periodo.';
    }
  }
}
