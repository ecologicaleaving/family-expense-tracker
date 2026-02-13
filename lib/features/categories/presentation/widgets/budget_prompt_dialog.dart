// Widget: Budget Prompt Dialog for Virgin Categories
// Feature: Italian Categories and Budget Management (004)
// Task: T040

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetPromptDialog extends StatefulWidget {
  const BudgetPromptDialog({
    super.key,
    required this.categoryName,
    required this.onDecline,
    required this.onSetBudget,
  });

  final String categoryName;
  final VoidCallback onDecline;
  final Function(int amount) onSetBudget;

  @override
  State<BudgetPromptDialog> createState() => _BudgetPromptDialogState();
}

class _BudgetPromptDialogState extends State<BudgetPromptDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Budget per "${widget.categoryName}"'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questa è la prima spesa nella categoria "${widget.categoryName}". '
              'Vuoi impostare un budget mensile?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Budget mensile',
                prefixText: '€ ',
                hintText: '500.00',
                helperText: 'Inserisci l\'importo del budget mensile',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un importo';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Importo non valido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onDecline();
          },
          child: const Text('Non ora'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final euros = double.parse(_controller.text);
              final cents = (euros * 100).toInt();
              Navigator.pop(context);
              widget.onSetBudget(cents);
            }
          },
          child: const Text('Imposta budget'),
        ),
      ],
    );
  }
}

/// Helper function to show budget prompt
Future<void> showBudgetPrompt({
  required BuildContext context,
  required String categoryName,
  required VoidCallback onDecline,
  required Function(int amount) onSetBudget,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false, // User must make a choice
    builder: (_) => BudgetPromptDialog(
      categoryName: categoryName,
      onDecline: onDecline,
      onSetBudget: onSetBudget,
    ),
  );
}
