import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../payment_methods/presentation/providers/payment_method_provider.dart';

/// Widget for selecting a payment method in expense forms.
///
/// Displays a dropdown with default payment methods followed by custom methods.
/// Default payment methods are shown first, then custom methods are grouped separately.
class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({
    super.key,
    required this.userId,
    this.selectedId,
    required this.onChanged,
    this.enabled = true,
  });

  final String userId;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodState = ref.watch(paymentMethodProvider(userId));

    // Show loading indicator while fetching
    if (paymentMethodState.isLoading && paymentMethodState.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error if failed to load
    if (paymentMethodState.hasError) {
      return ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: const Text('Errore nel caricamento'),
        subtitle: Text(paymentMethodState.errorMessage ?? 'Errore sconosciuto'),
      );
    }

    // Get default and custom methods
    final defaultMethods = paymentMethodState.defaultMethods;
    final customMethods = paymentMethodState.customMethods;

    // Build dropdown items
    final items = <DropdownMenuItem<String>>[];

    // Add default methods
    for (final method in defaultMethods) {
      items.add(
        DropdownMenuItem<String>(
          value: method.id,
          child: Row(
            children: [
              const Icon(Icons.payment, size: 20),
              const SizedBox(width: 8),
              Text(method.name),
            ],
          ),
        ),
      );
    }

    // Add separator if there are custom methods
    if (customMethods.isNotEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          enabled: false,
          value: null,
          child: Divider(),
        ),
      );

      // Add custom methods
      for (final method in customMethods) {
        items.add(
          DropdownMenuItem<String>(
            value: method.id,
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                Text(method.name),
              ],
            ),
          ),
        );
      }
    }

    // Determine selected value (default to Contanti if not set)
    final effectiveValue = selectedId ?? paymentMethodState.defaultContanti?.id;

    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: const InputDecoration(
        labelText: 'Metodo di Pagamento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.payment),
      ),
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleziona un metodo di pagamento';
        }
        return null;
      },
    );
  }
}
