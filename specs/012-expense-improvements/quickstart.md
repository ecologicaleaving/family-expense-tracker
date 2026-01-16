# Quickstart: Expense Management Improvements

**Feature**: 012-expense-improvements
**Audience**: Developers implementing this feature
**Prerequisites**: Flutter development environment, Supabase CLI, project cloned

## Overview

This guide helps you quickly implement the three expense management improvements:

1. ✅ **Deletion Confirmation** - Add confirmation dialogs before deleting expenses
2. ✅ **Income Display Fix** - Fix zero income bug on dashboard first load
3. ✅ **Reimbursable Expense Tracking** - Track expenses awaiting/received reimbursement

**Estimated Time**: 4-6 hours (excluding testing)

---

## Quick Start (TL;DR)

```bash
# 1. Database migration
supabase migration new add_reimbursement_tracking
# Copy SQL from data-model.md → migration file
supabase db push

# 2. Generate Dart code
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run tests
flutter test
flutter test integration_test

# 4. Manual testing checklist
# - Delete expense (confirm/cancel)
# - Delete reimbursable expense (see warning)
# - Mark expense as reimbursable
# - Mark as reimbursed
# - Check budget updates
# - Verify income shows on first launch
```

---

## Detailed Implementation Steps

### Step 1: Database Schema Migration (15 min)

#### 1.1 Create Supabase Migration

```bash
cd Fin/
supabase migration new add_reimbursement_tracking
```

#### 1.2 Copy Migration SQL

Open `supabase/migrations/YYYYMMDDHHMMSS_add_reimbursement_tracking.sql` and paste:

```sql
-- Add reimbursement columns to expenses table
ALTER TABLE public.expenses
ADD COLUMN reimbursement_status TEXT DEFAULT 'none' NOT NULL
  CHECK (reimbursement_status IN ('none', 'reimbursable', 'reimbursed')),
ADD COLUMN reimbursed_at TIMESTAMPTZ DEFAULT NULL;

-- Consistency constraint
ALTER TABLE public.expenses
ADD CONSTRAINT check_reimbursed_at_consistency
  CHECK (
    (reimbursement_status = 'reimbursed' AND reimbursed_at IS NOT NULL) OR
    (reimbursement_status != 'reimbursed' AND reimbursed_at IS NULL)
  );

-- Indexes for filtering
CREATE INDEX idx_expenses_reimbursement_status
  ON public.expenses(reimbursement_status)
  WHERE reimbursement_status != 'none';

CREATE INDEX idx_expenses_reimbursed_at
  ON public.expenses(reimbursed_at)
  WHERE reimbursed_at IS NOT NULL;

-- Documentation
COMMENT ON COLUMN public.expenses.reimbursement_status IS
  'Reimbursement tracking: none (default), reimbursable (awaiting), reimbursed (received)';
COMMENT ON COLUMN public.expenses.reimbursed_at IS
  'Timestamp when marked as reimbursed. Used for period-based budget calculations.';
```

#### 1.3 Apply Migration

```bash
# Local development
supabase db reset  # If needed
supabase db push

# Production (after testing)
supabase db push --linked
```

---

### Step 2: Core Dart Code Updates (30 min)

#### 2.1 Create Reimbursement Status Enum

**File**: `lib/core/enums/reimbursement_status.dart`

```dart
import 'package:flutter/material.dart';

enum ReimbursementStatus {
  none('none', 'Nessun rimborso'),
  reimbursable('reimbursable', 'Da rimborsare'),
  reimbursed('reimbursed', 'Rimborsato');

  const ReimbursementStatus(this.value, this.label);
  final String value;
  final String label;

  static ReimbursementStatus fromString(String value) {
    return ReimbursementStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReimbursementStatus.none,
    );
  }

  IconData get icon {
    switch (this) {
      case ReimbursementStatus.none:
        return Icons.check_circle_outline;
      case ReimbursementStatus.reimbursable:
        return Icons.schedule;
      case ReimbursementStatus.reimbursed:
        return Icons.check_circle;
    }
  }

  Color getColor(ColorScheme colorScheme) {
    switch (this) {
      case ReimbursementStatus.none:
        return colorScheme.onSurface;
      case ReimbursementStatus.reimbursable:
        return colorScheme.tertiary;
      case ReimbursementStatus.reimbursed:
        return colorScheme.primary;
    }
  }
}
```

#### 2.2 Update Expense Entity

**File**: `lib/features/expenses/domain/entities/expense_entity.dart`

Add fields and methods (see data-model.md for full code):

```dart
class ExpenseEntity extends Equatable {
  // ... existing fields ...
  final ReimbursementStatus reimbursementStatus;
  final DateTime? reimbursedAt;

  // Add to constructor
  const ExpenseEntity({
    // ... existing params ...
    this.reimbursementStatus = ReimbursementStatus.none,
    this.reimbursedAt,
  });

  // Add computed properties
  bool get isPendingReimbursement =>
      reimbursementStatus == ReimbursementStatus.reimbursable;
  bool get isReimbursed =>
      reimbursementStatus == ReimbursementStatus.reimbursed;

  // Add validation
  bool canTransitionTo(ReimbursementStatus newStatus) { /* ... */ }
  bool requiresConfirmation(ReimbursementStatus newStatus) { /* ... */ }

  // Add update method
  ExpenseEntity updateReimbursementStatus(ReimbursementStatus newStatus) {
    if (!canTransitionTo(newStatus)) {
      throw StateError('Invalid transition from $reimbursementStatus to $newStatus');
    }
    return copyWith(
      reimbursementStatus: newStatus,
      reimbursedAt: newStatus == ReimbursementStatus.reimbursed
          ? DateTime.now()
          : null,
    );
  }

  // Update props
  @override
  List<Object?> get props => [
    // ... existing props ...
    reimbursementStatus,
    reimbursedAt,
  ];
}
```

#### 2.3 Update Expense Model (Data Layer)

**File**: `lib/features/expenses/data/models/expense_model.dart`

```dart
class ExpenseModel extends ExpenseEntity {
  // Add to fromJson
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      // ... existing fields ...
      reimbursementStatus: ReimbursementStatus.fromString(
        json['reimbursement_status'] as String? ?? 'none',
      ),
      reimbursedAt: json['reimbursed_at'] != null
          ? DateTime.parse(json['reimbursed_at'] as String)
          : null,
    );
  }

  // Add to toJson
  Map<String, dynamic> toJson() {
    return {
      // ... existing fields ...
      'reimbursement_status': reimbursementStatus.value,
      'reimbursed_at': reimbursedAt?.toIso8601String(),
    };
  }
}
```

#### 2.4 Update Drift Table Definition

**File**: `lib/core/database/drift/tables/expenses.dart`

```dart
class Expenses extends Table {
  // ... existing columns ...

  TextColumn get reimbursementStatus => text()
      .withDefault(const Constant('none'))
      .check(reimbursementStatus.isIn(['none', 'reimbursable', 'reimbursed']))();

  DateTimeColumn get reimbursedAt => dateTime().nullable()();
}
```

#### 2.5 Generate Drift Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### Step 3: Budget Calculator Updates (20 min)

**File**: `lib/core/utils/budget_calculator.dart`

Add new methods:

```dart
class BudgetCalculator {
  // Existing method - no changes needed
  static int calculateSpentAmount(List<double> expenseAmounts) { /* ... */ }

  // NEW: Calculate reimbursed income for a specific period
  static int calculateReimbursedIncome({
    required List<ExpenseEntity> expenses,
    required int month,
    required int year,
  }) {
    final reimbursedExpenses = expenses.where((e) {
      if (e.reimbursementStatus != ReimbursementStatus.reimbursed) return false;
      if (e.reimbursedAt == null) return false;
      return e.reimbursedAt!.month == month && e.reimbursedAt!.year == year;
    });

    final total = reimbursedExpenses.fold(0.0, (sum, e) => sum + e.amount);
    return total.ceil();  // Round up like spent amount
  }

  // NEW: Calculate pending reimbursements
  static int calculatePendingReimbursements(List<ExpenseEntity> expenses) {
    final pending = expenses.where(
      (e) => e.reimbursementStatus == ReimbursementStatus.reimbursable,
    );
    return pending.fold(0.0, (sum, e) => sum + e.amount).ceil();
  }

  // MODIFIED: Include reimbursements in budget calculation
  static int calculateRemainingAmount({
    required int budgetAmount,
    required int spentAmount,
    int reimbursedIncome = 0,  // NEW parameter with default
  }) {
    return budgetAmount - spentAmount + reimbursedIncome;
  }

  // MODIFIED: Update percentage to account for reimbursements
  static double calculatePercentageUsed({
    required int budgetAmount,
    required int spentAmount,
    int reimbursedIncome = 0,  // NEW parameter
  }) {
    if (budgetAmount == 0) return 0.0;
    final netSpent = spentAmount - reimbursedIncome;
    return (netSpent / budgetAmount) * 100;
  }
}
```

---

### Step 4: UI Components (45 min)

#### 4.1 Delete Confirmation Dialog

**File**: `lib/features/expenses/presentation/widgets/delete_confirmation_dialog.dart`

```dart
import 'package:flutter/material.dart';

/// Shows confirmation dialog before deleting an expense
///
/// Returns:
/// - `true` if user confirms deletion
/// - `false` if user cancels
/// - `null` if dialog dismissed without action
Future<bool?> showDeleteConfirmationDialog(
  BuildContext context, {
  required bool isReimbursable,
  required String expenseName,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conferma eliminazione'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sei sicuro di voler eliminare questa spesa?'),
          if (isReimbursable) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Attenzione: questa spesa è in attesa di rimborso.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}
```

#### 4.2 Reimbursement Status Badge

**File**: `lib/shared/widgets/reimbursement_status_badge.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/enums/reimbursement_status.dart';

class ReimbursementStatusBadge extends StatelessWidget {
  final ReimbursementStatus status;
  final bool compact;

  const ReimbursementStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ReimbursementStatus.none) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final color = status.getColor(colorScheme);

    if (compact) {
      return Icon(status.icon, size: 16, color: color);
    }

    return Chip(
      avatar: Icon(status.icon, size: 16, color: color),
      label: Text(status.label),
      labelStyle: TextStyle(color: color, fontSize: 12),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }
}
```

#### 4.3 Update Expense List Item

**File**: `lib/features/expenses/presentation/widgets/expense_list_item.dart`

Add badge to existing widget:

```dart
// In the expense list item widget, add after amount display:
Row(
  children: [
    Text(expense.formattedAmount, style: amountStyle),
    const SizedBox(width: 8),
    ReimbursementStatusBadge(
      status: expense.reimbursementStatus,
      compact: true,
    ),
  ],
)
```

---

### Step 5: Provider Updates (30 min)

#### 5.1 Update Expense Provider with Delete Confirmation

**File**: `lib/features/expenses/presentation/providers/expense_provider.dart`

```dart
@riverpod
class ExpenseList extends _$ExpenseList {
  // ... existing code ...

  /// Delete expense with confirmation
  Future<void> deleteExpense(
    BuildContext context,
    String expenseId,
  ) async {
    final expense = state.value?.firstWhere((e) => e.id == expenseId);
    if (expense == null) return;

    // Show confirmation dialog
    final confirmed = await showDeleteConfirmationDialog(
      context,
      isReimbursable: expense.isPendingReimbursement,
      expenseName: expense.merchant ?? 'questa spesa',
    );

    if (confirmed != true) return; // User cancelled or dismissed

    // Proceed with deletion
    state = const AsyncValue.loading();

    final result = await ref
        .read(expenseRepositoryProvider)
        .deleteExpense(expenseId);

    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) {
        // Refresh list
        ref.invalidateSelf();
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spesa eliminata')),
        );
      },
    );
  }

  /// Update reimbursement status with confirmation if needed
  Future<void> updateReimbursementStatus(
    BuildContext context,
    String expenseId,
    ReimbursementStatus newStatus,
  ) async {
    final expense = state.value?.firstWhere((e) => e.id == expenseId);
    if (expense == null) return;

    // Check if confirmation needed (reverting from reimbursed)
    if (expense.requiresConfirmation(newStatus)) {
      final confirmed = await showReimbursementStatusChangeDialog(
        context,
        currentStatus: expense.reimbursementStatus,
        newStatus: newStatus,
      );
      if (confirmed != true) return;
    }

    // Update status
    try {
      final updatedExpense = expense.updateReimbursementStatus(newStatus);

      final result = await ref
          .read(expenseRepositoryProvider)
          .updateExpense(updatedExpense);

      result.fold(
        (failure) => _showError(context, failure.message),
        (_) {
          ref.invalidateSelf();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status aggiornato a: ${newStatus.label}')),
          );
        },
      );
    } on StateError catch (e) {
      _showError(context, e.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
```

#### 5.2 Fix Income Provider Initialization

**File**: `lib/features/budgets/presentation/providers/income_source_provider.dart`

```dart
@riverpod
Future<List<IncomeSource>> incomeSourcesList(IncomeSourcesListRef ref) async {
  final repository = ref.watch(incomeSourceRepositoryProvider);

  // CRITICAL FIX: Wait for auth to be ready before fetching
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];

  final result = await repository.getIncomeSources();

  return result.fold(
    (failure) {
      debugPrint('Failed to load income sources: ${failure.message}');
      return <IncomeSource>[];  // Graceful degradation
    },
    (sources) => sources,
  );
}
```

#### 5.3 Update Budget Stats Provider

**File**: `lib/features/budgets/presentation/providers/budget_provider.dart`

```dart
@riverpod
class BudgetStats extends _$BudgetStats {
  @override
  Future<BudgetStatsEntity> build({
    required String categoryId,
    required int month,
    required int year,
  }) async {
    final expenses = await ref.watch(expenseListProvider.future);

    // Filter expenses for this category and period
    final categoryExpenses = expenses.where((e) =>
        e.categoryId == categoryId &&
        e.date.month == month &&
        e.date.year == year).toList();

    // Calculate spent amount (existing logic)
    final spentAmount = BudgetCalculator.calculateSpentAmount(
      categoryExpenses.map((e) => e.amount).toList(),
    );

    // NEW: Calculate reimbursed income for this period
    final reimbursedIncome = BudgetCalculator.calculateReimbursedIncome(
      expenses: categoryExpenses,
      month: month,
      year: year,
    );

    // NEW: Calculate pending reimbursements
    final pendingReimbursements = BudgetCalculator.calculatePendingReimbursements(
      categoryExpenses,
    );

    // Get budget amount
    final budget = await ref.watch(categoryBudgetProvider(categoryId).future);
    final budgetAmount = budget?.amount ?? 0;

    return BudgetStatsEntity(
      spentAmount: spentAmount,
      isOverBudget: spentAmount >= budgetAmount,
      isNearLimit: spentAmount >= (budgetAmount * 0.8).ceil(),
      expenseCount: categoryExpenses.length,
      totalPendingReimbursements: pendingReimbursements,
      totalReimbursedIncome: reimbursedIncome,
    );
  }
}
```

---

### Step 6: Testing (60 min)

#### 6.1 Unit Tests

```bash
flutter test test/features/expenses/domain/entities/expense_entity_test.dart
flutter test test/core/utils/budget_calculator_test.dart
```

**Sample Test**: `test/features/expenses/domain/entities/expense_entity_test.dart`

```dart
void main() {
  group('ExpenseEntity Reimbursement', () {
    test('can transition from none to reimbursable', () {
      final expense = ExpenseEntity(/* ... */, reimbursementStatus: ReimbursementStatus.none);

      expect(expense.canTransitionTo(ReimbursementStatus.reimbursable), true);
    });

    test('requires confirmation when reverting from reimbursed', () {
      final expense = ExpenseEntity(/* ... */, reimbursementStatus: ReimbursementStatus.reimbursed);

      expect(expense.requiresConfirmation(ReimbursementStatus.none), true);
    });

    test('sets reimbursedAt when marking as reimbursed', () {
      final expense = ExpenseEntity(/* ... */, reimbursementStatus: ReimbursementStatus.reimbursable);

      final updated = expense.updateReimbursementStatus(ReimbursementStatus.reimbursed);

      expect(updated.reimbursedAt, isNotNull);
      expect(updated.reimbursementStatus, ReimbursementStatus.reimbursed);
    });
  });
}
```

#### 6.2 Widget Tests

```bash
flutter test test/features/expenses/presentation/widgets/delete_confirmation_dialog_test.dart
```

#### 6.3 Integration Tests

```bash
flutter test integration_test/expense_deletion_flow_test.dart
flutter test integration_test/reimbursement_workflow_test.dart
```

---

### Step 7: Manual Testing Checklist

```markdown
- [ ] Delete regular expense
  - [ ] Dialog appears with "Conferma eliminazione"
  - [ ] Cancel button works
  - [ ] Confirm button deletes expense
- [ ] Delete reimbursable expense
  - [ ] Warning message appears
  - [ ] Still allows deletion if confirmed
- [ ] Mark expense as reimbursable
  - [ ] Badge shows "Da rimborsare"
  - [ ] Pending total updates in budget overview
- [ ] Mark reimbursable expense as reimbursed
  - [ ] Badge shows "Rimborsato"
  - [ ] Budget remaining increases
  - [ ] Reimbursed total shows in summary
- [ ] Revert reimbursed expense
  - [ ] Confirmation dialog appears
  - [ ] Status changes after confirmation
  - [ ] Budget recalculates correctly
- [ ] Dashboard income display
  - [ ] Clear app data
  - [ ] Relaunch app
  - [ ] Income shows correct value (not zero)
  - [ ] Offline banner shows if no network
```

---

## Common Issues & Troubleshooting

### Issue: Migration fails with "column already exists"

**Solution**: Drop the columns first or reset local DB:
```bash
supabase db reset
```

### Issue: Drift compilation errors

**Solution**: Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Income still shows zero on first launch

**Solution**: Check provider initialization order in `lib/app/app.dart`:
```dart
// Ensure income provider is watched before dashboard renders
await ref.read(incomeSourcesListProvider.future);
```

### Issue: Delete confirmation not showing

**Solution**: Verify you're using `await` before `showDeleteConfirmationDialog`:
```dart
final confirmed = await showDeleteConfirmationDialog(...);
```

---

## Performance Checklist

- [ ] Database indexes created for `reimbursement_status` and `reimbursed_at`
- [ ] Budget calculations cached in provider (don't recalculate on every widget build)
- [ ] Expense list uses pagination (existing - verify still works)
- [ ] Dialog animations smooth (<16ms frame time)

---

## Next Steps After Implementation

1. **Run full test suite**: `flutter test && flutter test integration_test`
2. **Test on real device**: Install dev flavor and test workflows
3. **Update user documentation**: Add help text for reimbursement feature
4. **Monitor Supabase logs**: Check for query performance
5. **Create GitHub PR**: Use `/dev-workflow` skill for PR creation

---

## Resources

- **Spec**: `specs/012-expense-improvements/spec.md`
- **Plan**: `specs/012-expense-improvements/plan.md`
- **Data Model**: `specs/012-expense-improvements/data-model.md`
- **Research**: `specs/012-expense-improvements/research.md`
- **Existing Dialog Pattern**: `lib/features/budgets/presentation/widgets/budget_prompt_dialog.dart`
- **Existing Calculator**: `lib/core/utils/budget_calculator.dart`

---

**Ready to start?** Begin with Step 1 (Database Migration) and work through sequentially. Estimated total time: 4-6 hours + testing.
