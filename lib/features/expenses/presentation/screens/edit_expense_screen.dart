import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/navigation_guard.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/expenses_chart_widget.dart';
import '../../../dashboard/presentation/widgets/personal_dashboard_view.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/payment_method_selector.dart';

/// Screen for editing an existing expense.
/// Loads the expense by ID and displays an edit form.
class EditExpenseScreen extends ConsumerWidget {
  const EditExpenseScreen({
    super.key,
    required this.expenseId,
  });

  /// The ID of the expense to edit.
  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseAsync = ref.watch(expenseProvider(expenseId));

    return expenseAsync.when(
      data: (expense) {
        if (expense == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: const Text('Modifica spesa'),
            ),
            body: const ErrorDisplay(
              message: 'Spesa non trovata',
              icon: Icons.error_outline,
            ),
          );
        }
        return _EditExpenseForm(expense: expense);
      },
      loading: () => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Modifica spesa'),
        ),
        body: const LoadingIndicator(message: 'Caricamento...'),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Modifica spesa'),
        ),
        body: ErrorDisplay(
          message: error.toString(),
          onRetry: () => ref.invalidate(expenseProvider(expenseId)),
        ),
      ),
    );
  }
}

/// Internal form widget for editing expense.
class _EditExpenseForm extends ConsumerStatefulWidget {
  const _EditExpenseForm({
    required this.expense,
  });

  final ExpenseEntity expense;

  @override
  ConsumerState<_EditExpenseForm> createState() => _EditExpenseFormState();
}

class _EditExpenseFormState extends ConsumerState<_EditExpenseForm>
    with UnsavedChangesGuard {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedCategoryId;
  String? _selectedPaymentMethodId;
  late bool _isGroupExpense;

  // Track initial values for unsaved changes detection
  late String _initialAmount;
  late String _initialMerchant;
  late String _initialNotes;
  late DateTime _initialDate;
  String? _initialCategoryId;
  String? _initialPaymentMethodId;
  late bool _initialIsGroupExpense;

  @override
  void initState() {
    super.initState();
    // Reset form provider state to ensure clean start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseFormProvider.notifier).reset();
    });

    // Initialize form with existing expense data
    _amountController.text = widget.expense.amount.toStringAsFixed(2);
    _merchantController.text = widget.expense.merchant ?? '';
    _notesController.text = widget.expense.notes ?? '';
    _selectedDate = widget.expense.date;
    _selectedCategoryId = widget.expense.categoryId;
    _selectedPaymentMethodId = widget.expense.paymentMethodId;
    _isGroupExpense = widget.expense.isGroupExpense;

    // Store initial values for change detection
    _initialAmount = _amountController.text;
    _initialMerchant = _merchantController.text;
    _initialNotes = _notesController.text;
    _initialDate = _selectedDate;
    _initialCategoryId = _selectedCategoryId;
    _initialPaymentMethodId = _selectedPaymentMethodId;
    _initialIsGroupExpense = _isGroupExpense;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  bool get hasUnsavedChanges {
    return _amountController.text != _initialAmount ||
        _merchantController.text != _initialMerchant ||
        _notesController.text != _initialNotes ||
        _selectedDate != _initialDate ||
        _selectedCategoryId != _initialCategoryId ||
        _selectedPaymentMethodId != _initialPaymentMethodId ||
        _isGroupExpense != _initialIsGroupExpense;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = Validators.parseAmount(_amountController.text);
    if (amount == null) {
      return;
    }
    final formNotifier = ref.read(expenseFormProvider.notifier);
    final listNotifier = ref.read(expenseListProvider.notifier);

    var updatedExpense = await formNotifier.updateExpense(
      expenseId: widget.expense.id,
      amount: amount,
      date: _selectedDate,
      categoryId: _selectedCategoryId,
      paymentMethodId: _selectedPaymentMethodId,
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (updatedExpense == null) {
      // Show error and return - user can try again or discard changes
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(expenseFormProvider).errorMessage ?? 'Errore durante il salvataggio'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    // Update expense classification if changed
    if (_isGroupExpense != _initialIsGroupExpense) {
      updatedExpense = await formNotifier.updateExpenseClassification(
        expenseId: widget.expense.id,
        isGroupExpense: _isGroupExpense,
      );

      if (updatedExpense == null) {
        // Classification update failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ref.read(expenseFormProvider).errorMessage ?? 'Errore durante il cambio di classificazione'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      listNotifier.updateExpenseInList(updatedExpense);

      // Invalidate providers to force refresh on detail page and dashboard
      ref.invalidate(expenseProvider(widget.expense.id));
      ref.invalidate(recentGroupExpensesProvider);
      ref.invalidate(recentPersonalExpensesProvider);
      ref.invalidate(personalExpensesByCategoryProvider);
      ref.invalidate(expensesByPeriodProvider);
      ref.read(dashboardProvider.notifier).refresh();

      // Reset initial values to match saved values so hasUnsavedChanges becomes false
      setState(() {
        _initialAmount = _amountController.text;
        _initialMerchant = _merchantController.text;
        _initialNotes = _notesController.text;
        _initialDate = _selectedDate;
        _initialCategoryId = _selectedCategoryId;
        _initialPaymentMethodId = _selectedPaymentMethodId;
        _initialIsGroupExpense = _isGroupExpense;
      });

      // Wait for setState rebuild to complete before navigating back
      // This ensures PopScope sees the updated hasUnsavedChanges value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          context.go('/expense/${widget.expense.id}');
        }
      });
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

    return buildWithNavigationGuard(
      context,
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await confirmDiscardChanges(context);
              if (shouldPop && mounted) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: const Text('Modifica spesa'),
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
                  autofocus: false,
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
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (categoryId) {
                    setState(() {
                      _selectedCategoryId = categoryId;
                    });
                  },
                  enabled: !formState.isSubmitting,
                ),
                const SizedBox(height: 16),

                // Payment method selector
                PaymentMethodSelector(
                  userId: ref.watch(currentUserIdProvider),
                  selectedId: _selectedPaymentMethodId,
                  onChanged: (paymentMethodId) {
                    setState(() {
                      _selectedPaymentMethodId = paymentMethodId;
                    });
                  },
                  enabled: !formState.isSubmitting,
                ),
                const SizedBox(height: 16),

                // Group/Personal toggle
                SwitchListTile(
                  title: const Text('Spesa di gruppo'),
                  subtitle: Text(
                    _isGroupExpense
                        ? 'Visibile a tutti i membri del gruppo'
                        : 'Visibile solo a te',
                  ),
                  value: _isGroupExpense,
                  onChanged: formState.isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _isGroupExpense = value;
                          });
                        },
                  secondary: Icon(
                    _isGroupExpense ? Icons.group : Icons.person,
                  ),
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
                  label: 'Salva modifiche',
                  isLoading: formState.isSubmitting,
                  loadingLabel: 'Salvataggio...',
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
