import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_selector.dart';

/// Screen for manual expense entry.
class ManualExpenseScreen extends ConsumerStatefulWidget {
  const ManualExpenseScreen({super.key});

  @override
  ConsumerState<ManualExpenseScreen> createState() => _ManualExpenseScreenState();
}

class _ManualExpenseScreenState extends ConsumerState<ManualExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.altro;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = Validators.parseAmount(_amountController.text);
    if (amount == null) return;

    final formNotifier = ref.read(expenseFormProvider.notifier);
    final listNotifier = ref.read(expenseListProvider.notifier);

    final expense = await formNotifier.createExpense(
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (expense != null && mounted) {
      listNotifier.addExpense(expense);
      // Refresh dashboard to reflect the new expense
      ref.read(dashboardProvider.notifier).refresh();
      context.pop(); // Return to previous screen (MainNavigationScreen with Spese tab)
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(expenseFormProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Nuova spesa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (formState.hasError && formState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InlineError(message: formState.errorMessage!),
                ),

              // Amount field
              AmountTextField(
                controller: _amountController,
                validator: Validators.validateAmount,
                enabled: !formState.isSubmitting,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Date field
              InkWell(
                onTap: formState.isSubmitting ? null : _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormatter.formatFullDate(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Merchant field
              CustomTextField(
                controller: _merchantController,
                label: 'Negozio',
                hint: 'Nome del negozio (opzionale)',
                prefixIcon: Icons.store_outlined,
                enabled: !formState.isSubmitting,
                validator: Validators.validateMerchant,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Category selector
              CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                enabled: !formState.isSubmitting,
              ),
              const SizedBox(height: 16),

              // Notes field
              CustomTextField(
                controller: _notesController,
                label: 'Note',
                hint: 'Note aggiuntive (opzionale)',
                prefixIcon: Icons.notes_outlined,
                enabled: !formState.isSubmitting,
                validator: Validators.validateNotes,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Save button
              PrimaryButton(
                onPressed: _handleSave,
                label: 'Salva spesa',
                isLoading: formState.isSubmitting,
                loadingLabel: 'Salvataggio...',
                icon: Icons.check,
              ),

              const SizedBox(height: 16),

              // Or scan button
              SecondaryButton(
                onPressed: () => context.go('/scan-receipt'),
                label: 'Scansiona scontrino',
                icon: Icons.document_scanner,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
