import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/payment_method_entity.dart';
import '../providers/payment_method_actions_provider.dart';
import '../providers/payment_method_provider.dart';

/// Dialog for creating or editing a payment method
class PaymentMethodFormDialog extends ConsumerStatefulWidget {
  const PaymentMethodFormDialog({
    super.key,
    required this.userId,
    this.paymentMethod,
  });

  final String userId;
  final PaymentMethodEntity? paymentMethod;

  @override
  ConsumerState<PaymentMethodFormDialog> createState() =>
      _PaymentMethodFormDialogState();
}

class _PaymentMethodFormDialogState
    extends ConsumerState<PaymentMethodFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMethod != null) {
      _nameController.text = widget.paymentMethod!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.paymentMethod != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifica Metodo' : 'Nuovo Metodo di Pagamento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
                hintText: 'es. PayPal, Postepay, ecc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Inserisci un nome';
                }
                if (value.trim().length > 50) {
                  return 'Massimo 50 caratteri';
                }
                return null;
              },
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Salva' : 'Crea'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final actions = ref.read(paymentMethodActionsProvider);
      final isEdit = widget.paymentMethod != null;

      if (isEdit) {
        await actions.updatePaymentMethod(
          id: widget.paymentMethod!.id,
          userId: widget.userId,
          name: _nameController.text.trim(),
        );
      } else {
        await actions.createPaymentMethod(
          userId: widget.userId,
          name: _nameController.text.trim(),
        );
      }

      // Refresh payment methods list
      ref.invalidate(paymentMethodProvider(widget.userId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Metodo di pagamento aggiornato'
                  : 'Metodo di pagamento creato',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
