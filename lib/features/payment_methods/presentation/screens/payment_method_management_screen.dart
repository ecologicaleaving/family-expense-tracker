import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/payment_method_provider.dart';
import '../providers/payment_method_actions_provider.dart';
import '../widgets/payment_method_form_dialog.dart';
import '../widgets/payment_method_list_item.dart';

/// Payment Method management screen
class PaymentMethodManagementScreen extends ConsumerWidget {
  const PaymentMethodManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final paymentMethodState = ref.watch(paymentMethodProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metodi di Pagamento'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPaymentMethodDialog(context, ref, userId),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi Metodo'),
      ),
      body: paymentMethodState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : paymentMethodState.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        paymentMethodState.errorMessage ?? 'Errore sconosciuto',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(paymentMethodProvider(userId).notifier).loadPaymentMethods();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Riprova'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Default payment methods section
                    if (paymentMethodState.defaultMethods.isNotEmpty) ...[
                      Text(
                        'Metodi Predefiniti',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Questi metodi di pagamento sono predefiniti e non possono essere modificati o eliminati.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...paymentMethodState.defaultMethods.map(
                        (method) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PaymentMethodListItem(
                            paymentMethod: method,
                            userId: userId,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Custom payment methods section
                    Text(
                      'Metodi Personalizzati',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      paymentMethodState.customMethods.isEmpty
                          ? 'Nessun metodo personalizzato. Creane uno per gestire meglio le tue spese.'
                          : 'I tuoi metodi di pagamento personalizzati. Puoi modificarli o eliminarli.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (paymentMethodState.customMethods.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun metodo personalizzato',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...paymentMethodState.customMethods.map(
                        (method) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PaymentMethodListItem(
                            paymentMethod: method,
                            userId: userId,
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Future<void> _showAddPaymentMethodDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => PaymentMethodFormDialog(userId: userId),
    );
  }
}
