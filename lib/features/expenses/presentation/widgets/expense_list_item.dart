import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/reimbursement_status_badge.dart';
import '../../domain/entities/expense_entity.dart';

/// List item widget for displaying expense summary in a list.
class ExpenseListItem extends StatelessWidget {
  const ExpenseListItem({
    super.key,
    required this.expense,
    required this.onTap,
  });

  final ExpenseEntity expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount (first line, prominent)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense.formattedAmount,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  ReimbursementStatusBadge(
                    status: expense.reimbursementStatus,
                    mode: ReimbursementBadgeMode.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Negozio (Merchant)
              if (expense.merchant != null && expense.merchant!.isNotEmpty)
                _buildDetailRow(
                  context,
                  icon: Icons.store,
                  label: 'Negozio',
                  value: expense.merchant!,
                ),

              // Note
              if (expense.notes != null && expense.notes!.isNotEmpty)
                _buildDetailRow(
                  context,
                  icon: Icons.notes,
                  label: 'Note',
                  value: expense.notes!,
                ),

              // Categoria
              _buildDetailRow(
                context,
                icon: Icons.category,
                label: 'Categoria',
                value: expense.categoryName ?? 'N/A',
              ),

              // Data
              _buildDetailRow(
                context,
                icon: Icons.calendar_today,
                label: 'Data',
                value: DateFormatter.formatRelativeDate(expense.date),
              ),

              // Tipo metodo (Payment method)
              if (expense.paymentMethodName != null)
                _buildDetailRow(
                  context,
                  icon: Icons.payment,
                  label: 'Metodo',
                  value: expense.paymentMethodName!,
                ),

              // Autore (Creator) - Only for group expenses
              if (expense.isGroupExpense && expense.createdByName != null)
                _buildDetailRow(
                  context,
                  icon: Icons.person,
                  label: 'Autore',
                  value: expense.createdByName!,
                  highlight: true,
                ),

              // Expense type indicator with icons
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    expense.isGroupExpense ? Icons.group : Icons.lock_person,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expense.isGroupExpense ? 'Spesa di gruppo' : 'Spesa personale',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (expense.hasReceipt) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  if (expense.isRecurringExpense) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.loop,
                      size: 16,
                      color: theme.colorScheme.tertiary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                    color: highlight
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

