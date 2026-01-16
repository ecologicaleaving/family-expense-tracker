import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/enums/reimbursement_status.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/error_display.dart';
import '../../../../shared/widgets/navigation_guard.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/presentation/providers/budget_repository_provider.dart';
import '../../../categories/presentation/providers/category_provider.dart';
import '../../../categories/presentation/providers/category_repository_provider.dart';
import '../../../categories/presentation/widgets/budget_prompt_dialog.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../dashboard/presentation/widgets/expenses_chart_widget.dart';
import '../../../dashboard/presentation/widgets/personal_dashboard_view.dart';
import '../../../groups/presentation/providers/group_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/expense_type_toggle.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/reimbursement_toggle.dart';

/// Screen for manual expense entry.
class ManualExpenseScreen extends ConsumerStatefulWidget {
  const ManualExpenseScreen({super.key});

  @override
  ConsumerState<ManualExpenseScreen> createState() => _ManualExpenseScreenState();
}

class _ManualExpenseScreenState extends ConsumerState<ManualExpenseScreen>
    with UnsavedChangesGuard {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId; // Will be set when categories load
  String? _selectedPaymentMethodId; // Will be set to default Contanti
  bool _isGroupExpense = true; // Default to group expense
  ReimbursementStatus _selectedReimbursementStatus = ReimbursementStatus.none; // T035

  // Track initial values for unsaved changes detection
  late final String _initialAmount;
  late final String _initialMerchant;
  late final String _initialNotes;
  late final DateTime _initialDate;
  late final String? _initialCategoryId;
  late final String? _initialPaymentMethodId;
  late final bool _initialIsGroupExpense;
  late final ReimbursementStatus _initialReimbursementStatus; // T035

  @override
  void initState() {
    super.initState();
    // Store initial values
    _initialAmount = _amountController.text;
    _initialMerchant = _merchantController.text;
    _initialNotes = _notesController.text;
    _initialDate = _selectedDate;
    _initialCategoryId = _selectedCategoryId;
    _initialPaymentMethodId = _selectedPaymentMethodId;
    _initialIsGroupExpense = _isGroupExpense;
    _initialReimbursementStatus = _selectedReimbursementStatus; // T035
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
        _isGroupExpense != _initialIsGroupExpense ||
        _selectedReimbursementStatus != _initialReimbursementStatus; // T035
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = Validators.parseAmount(_amountController.text);
    if (amount == null) return;

    // Validate category is selected
    if (_selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona una categoria')),
        );
      }
      return;
    }

    // Validate payment method is selected
    if (_selectedPaymentMethodId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona un metodo di pagamento')),
        );
      }
      return;
    }

    final formNotifier = ref.read(expenseFormProvider.notifier);
    final listNotifier = ref.read(expenseListProvider.notifier);

    final expense = await formNotifier.createExpense(
      amount: amount,
      date: _selectedDate,
      categoryId: _selectedCategoryId!,
      paymentMethodId: _selectedPaymentMethodId!,
      merchant: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      isGroupExpense: _isGroupExpense,
      reimbursementStatus: _selectedReimbursementStatus, // T035
    );

    if (expense != null && mounted) {
      listNotifier.addExpense(expense);

      // Check for virgin category and show budget prompt (Feature 004: T041-T044)
      await _checkAndPromptForVirginCategory();

      // Refresh dashboard to reflect the new expense
      ref.read(dashboardProvider.notifier).refresh();

      // Invalidate personal dashboard providers to refresh totals
      ref.invalidate(personalExpensesByCategoryProvider);
      ref.invalidate(expensesByPeriodProvider);
      ref.invalidate(recentPersonalExpensesProvider);

      if (mounted) {
        context.pop(); // Return to previous screen (MainNavigationScreen with Spese tab)
      }
    }
  }

  /// Check if this is the first time user uses this category, and show budget prompt if so.
  /// Feature 004: Virgin Category Prompts (T041-T044)
  Future<void> _checkAndPromptForVirginCategory() async {
    if (_selectedCategoryId == null || !mounted) return;

    final userId = ref.read(currentUserIdProvider);
    final categoryRepository = ref.read(categoryRepositoryProvider);
    final budgetRepository = ref.read(budgetRepositoryProvider);
    final groupId = ref.read(currentGroupIdProvider);

    // Check if user has used this category before (T041)
    final hasUsedResult = await categoryRepository.hasUserUsedCategory(
      userId: userId,
      categoryId: _selectedCategoryId!,
    );

    final hasUsed = hasUsedResult.fold(
      (failure) => true, // On error, assume used to avoid showing prompt
      (hasUsed) => hasUsed,
    );

    if (hasUsed) return; // Category already used, no prompt needed

    // Get category name for the prompt
    final categoriesState = ref.read(categoryProvider(groupId));
    try {
      final category = categoriesState.categories.firstWhere(
        (cat) => cat.id == _selectedCategoryId,
      );

      if (!mounted) return;

      // Show budget prompt dialog (T041, T042)
      await showBudgetPrompt(
        context: context,
        categoryName: category.name,
        onDecline: () {
          // User declined - do nothing (T042)
          // Could optionally use "Varie" budget, but spec says just track usage
        },
        onSetBudget: (amountInCents) async {
          // User set a budget - save it (T042)
          final now = DateTime.now();
          await budgetRepository.createCategoryBudget(
            categoryId: _selectedCategoryId!,
            groupId: groupId,
            amount: amountInCents,
            month: now.month,
            year: now.year,
          );
        },
      );

      // Mark category as used for this user (T043)
      await categoryRepository.markCategoryAsUsed(
        userId: userId,
        categoryId: _selectedCategoryId!,
      );

      // Refresh category budgets to show the new budget if created
      ref.invalidate(categoryProvider(groupId));
    } catch (e) {
      // Category not found or error occurred - skip prompt
      return;
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

              // Expense type toggle
              Text(
                'Tipo di spesa',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ExpenseTypeToggle(
                isGroupExpense: _isGroupExpense,
                onChanged: (value) {
                  setState(() {
                    _isGroupExpense = value;
                  });
                },
                enabled: !formState.isSubmitting,
              ),
              const SizedBox(height: 8),
              Text(
                _isGroupExpense
                    ? 'Visibile a tutti i membri del gruppo'
                    : 'Visibile solo a te',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
              Consumer(
                builder: (context, ref, child) {
                  final userId = ref.watch(currentUserIdProvider);
                  return PaymentMethodSelector(
                    userId: userId,
                    selectedId: _selectedPaymentMethodId,
                    onChanged: (paymentMethodId) {
                      setState(() {
                        _selectedPaymentMethodId = paymentMethodId;
                      });
                    },
                    enabled: !formState.isSubmitting,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Reimbursement status toggle (T035)
              ReimbursementToggle(
                value: _selectedReimbursementStatus,
                onChanged: (status) {
                  setState(() {
                    _selectedReimbursementStatus = status;
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
      ),
    );
  }
}
