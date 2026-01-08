import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../providers/payment_method_actions_provider.dart';
import '../providers/payment_method_provider.dart';
import 'payment_method_form_dialog.dart';

/// List item widget for displaying a payment method
class PaymentMethodListItem extends ConsumerWidget {
  const PaymentMethodListItem({
    super.key,
    required this.paymentMethod,
    required this.userId,
  });

  final PaymentMethodEntity paymentMethod;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDefault = paymentMethod.isDefault;

    return Card(
      child: ListTile(
        leading: Icon(
          isDefault ? Icons.payment : Icons.account_balance_wallet,
          color: theme.colorScheme.primary,
        ),
        title: Text(paymentMethod.name),
        subtitle: paymentMethod.expenseCount != null && paymentMethod.expenseCount! > 0
            ? Text('Usato in ${paymentMethod.expenseCount} spesa/e')
            : null,
        trailing: isDefault
            ? Chip(
                label: const Text('Predefinito'),
                backgroundColor: theme.colorScheme.primaryContainer,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _handleEdit(context, ref),
                    tooltip: 'Modifica',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _handleDelete(context, ref),
                    tooltip: 'Elimina',
                    color: Colors.red,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => PaymentMethodFormDialog(
        userId: userId,
        paymentMethod: paymentMethod,
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    // Get expense count first
    final actions = ref.read(paymentMethodActionsProvider);
    final count = await actions.getPaymentMethodExpenseCount(id: paymentMethod.id);

    if (!context.mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina metodo di pagamento'),
        content: count > 0
            ? Text(
                'Questo metodo di pagamento è usato in $count spesa/e. '
                'Non puoi eliminarlo.',
              )
            : Text(
                'Sei sicuro di voler eliminare "${paymentMethod.name}"?',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          if (count == 0)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Elimina'),
            ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Delete payment method
    try {
      await actions.deletePaymentMethod(id: paymentMethod.id);

      // Refresh list
      ref.invalidate(paymentMethodProvider(userId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metodo di pagamento eliminato'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
