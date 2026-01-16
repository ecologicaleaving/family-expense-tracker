import 'package:flutter/material.dart';

/// Deletion confirmation dialog for expenses.
///
/// Shows a confirmation dialog when deleting an expense, with an additional
/// warning if the expense is marked as reimbursable.
///
/// Feature 012-expense-improvements - User Story 1 (T014-T015)
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.expenseName,
    this.isReimbursable = false,
  });

  /// Name or description of the expense being deleted (e.g., merchant name or amount)
  final String expenseName;

  /// Whether this expense is pending reimbursement
  final bool isReimbursable;

  /// Show the delete confirmation dialog
  ///
  /// Returns `true` if user confirmed deletion, `false` if cancelled, or `null` if dismissed
  static Future<bool?> show(
    BuildContext context, {
    required String expenseName,
    bool isReimbursable = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        expenseName: expenseName,
        isReimbursable: isReimbursable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning_rounded,
        color: colorScheme.error,
        size: 32,
      ),
      title: const Text('Elimina spesa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sei sicuro di voler eliminare questa spesa?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            expenseName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isReimbursable) ...[
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
                      'Attenzione: questa spesa è in attesa di rimborso. Se la elimini, perderai il riferimento per il rimborso.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Questa azione non può essere annullata.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Elimina'),
        ),
      ],
    );
  }
}
