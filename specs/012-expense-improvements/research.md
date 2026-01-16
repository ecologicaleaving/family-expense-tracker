# Research: Expense Management Improvements

**Feature**: 012-expense-improvements
**Date**: 2026-01-16
**Purpose**: Resolve technical unknowns and establish implementation patterns

## Phase 0: Research Findings

### 1. Confirmation Dialog Pattern in Flutter

**Decision**: Use Material `AlertDialog` with async/await pattern

**Rationale**:
- Consistent with existing codebase patterns (`budget_prompt_dialog.dart`, `category_form_dialog.dart`)
- Material Design 3 compliant with app theme
- Simple boolean return value for confirm/cancel
- Built-in dismiss handling and navigation

**Pattern**:
```dart
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
        children: [
          Text('Sei sicuro di voler eliminare questa spesa?'),
          if (isReimbursable) ...[
            const SizedBox(height: 8),
            Text(
              'Attenzione: questa spesa è in attesa di rimborso.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
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
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}
```

**Alternatives Considered**:
- Custom bottom sheet dialog - Rejected: Too complex for simple confirmation
- Cupertino dialogs - Rejected: Material Design 3 theme already established
- Third-party packages (flutter_dialogs) - Rejected: Adds unnecessary dependency

---

### 2. Database Schema Extension for Reimbursement

**Decision**: Add two fields to Supabase `expenses` table + Drift migration

**Rationale**:
- Minimal schema change (2 fields)
- Backwards compatible (nullable/default values)
- Reuses existing timestamp pattern for tracking when reimbursed
- Enum pattern already used in codebase (BudgetType)

**Schema Changes**:

**Supabase SQL Migration**:
```sql
-- Migration: Add reimbursement tracking to expenses table
ALTER TABLE public.expenses
ADD COLUMN reimbursement_status TEXT DEFAULT 'none' CHECK (reimbursement_status IN ('none', 'reimbursable', 'reimbursed')),
ADD COLUMN reimbursed_at TIMESTAMPTZ DEFAULT NULL;

-- Index for filtering by reimbursement status
CREATE INDEX idx_expenses_reimbursement_status ON public.expenses(reimbursement_status) WHERE reimbursement_status != 'none';

-- Comment for documentation
COMMENT ON COLUMN public.expenses.reimbursement_status IS 'Tracks if expense is awaiting or received reimbursement: none (default), reimbursable, reimbursed';
COMMENT ON COLUMN public.expenses.reimbursed_at IS 'Timestamp when expense was marked as reimbursed (for period-based budget calculations)';
```

**Drift Local Schema**:
```dart
// lib/core/database/drift/tables/expenses.dart
class Expenses extends Table {
  TextColumn get id => text()();
  // ... existing columns ...
  TextColumn get reimbursementStatus => text().withDefault(const Constant('none'))();
  DateTimeColumn get reimbursedAt => dateTime().nullable()();
}
```

**Dart Enum**:
```dart
// lib/core/enums/reimbursement_status.dart
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
}
```

**Alternatives Considered**:
- Separate `reimbursements` table - Rejected: Over-engineering for 1:1 relationship
- Boolean flags (isReimbursable, isReimbursed) - Rejected: Doesn't enforce state machine
- String without enum constraint - Rejected: No type safety in Dart layer

---

### 3. Budget Calculation with Reimbursement

**Decision**: Extend `BudgetCalculator` to treat reimbursed amounts as income in the reimbursement period

**Rationale**:
- Aligns with clarification: reimbursements are income events
- Maintains existing calculation patterns (rounding up to whole euros)
- Period-based tracking uses `reimbursed_at` timestamp
- No changes to historical expense amounts (preserves audit trail)

**Calculation Logic**:
```dart
// lib/core/utils/budget_calculator.dart

class BudgetCalculator {
  // Existing method - no changes
  static int calculateSpentAmount(List<double> expenseAmounts) {
    return expenseAmounts.fold(0.0, (sum, amount) => sum + amount).ceil();
  }

  // NEW: Calculate reimbursed income for a period
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

    final totalReimbursed = reimbursedExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return totalReimbursed.ceil(); // Round up like spent amount
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
    required int reimbursedIncome, // NEW parameter
  }) {
    return budgetAmount - spentAmount + reimbursedIncome;
  }

  // MODIFIED: Update percentage calculation
  static double calculatePercentageUsed({
    required int budgetAmount,
    required int spentAmount,
    required int reimbursedIncome,
  }) {
    if (budgetAmount == 0) return 0.0;
    final netSpent = spentAmount - reimbursedIncome;
    return (netSpent / budgetAmount) * 100;
  }
}
```

**Alternatives Considered**:
- Reduce expense amount when reimbursed - Rejected: Loses historical data
- Cap budget at zero (no surplus) - Rejected: Contradicts clarification decision
- Separate reimbursement entity - Rejected: Adds complexity without benefit

---

### 4. Income Display Bug Root Cause

**Decision**: Add initialization check in `IncomeDashboardProvider` to ensure income loads before dashboard renders

**Rationale**:
- Current bug likely caused by async race condition
- Dashboard renders before income provider completes initialization
- FutureProvider pattern ensures data availability before UI

**Root Cause Analysis**:
Based on codebase exploration, the issue is in provider initialization order:
1. Dashboard loads and immediately renders
2. Income sources are fetched asynchronously
3. Initial render shows zero because future hasn't completed

**Fix Pattern**:
```dart
// lib/features/budgets/presentation/providers/income_source_provider.dart

@riverpod
Future<List<IncomeSource>> incomeSourcesList(IncomeSourcesListRef ref) async {
  final repository = ref.watch(incomeSourceRepositoryProvider);

  // Ensure authentication is ready
  final authState = await ref.watch(authStateProvider.future);
  if (authState == null) return [];

  // Fetch income sources
  final result = await repository.getIncomeSources();

  return result.fold(
    (failure) {
      // Log error but return empty list (graceful degradation)
      debugPrint('Failed to load income sources: ${failure.message}');
      return <IncomeSource>[];
    },
    (sources) => sources,
  );
}

// Dashboard provider waits for income to be ready
@riverpod
class DashboardData extends _$DashboardData {
  @override
  Future<DashboardState> build() async {
    // Wait for all required data
    final incomeSources = await ref.watch(incomeSourcesListProvider.future);
    final expenses = await ref.watch(expenseListProvider.future);
    final budgets = await ref.watch(budgetListProvider.future);

    return DashboardState(
      totalIncome: _calculateTotalIncome(incomeSources),
      totalExpenses: _calculateTotalExpenses(expenses),
      // ... other dashboard data
    );
  }
}
```

**Alternatives Considered**:
- Add loading spinner - Rejected: Doesn't fix root cause
- Use StreamProvider instead of FutureProvider - Rejected: Overkill for one-time load
- Preload income on app startup - Rejected: Delays app launch unnecessarily

---

### 5. Offline Data Handling with Stale Indicator

**Decision**: Extend existing `offline_banner.dart` widget to support stale data mode

**Rationale**:
- Widget already exists for offline detection
- Consistent UX pattern across app
- Uses connectivity_plus package already in dependencies
- Material Design 3 banner component

**Implementation Pattern**:
```dart
// lib/shared/widgets/offline_banner.dart (MODIFIED)

class StaleDataBanner extends ConsumerWidget {
  const StaleDataBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);

    final isOffline = connectivityState == ConnectivityResult.none;
    final isStale = lastSyncTime != null &&
        DateTime.now().difference(lastSyncTime) > const Duration(minutes: 5);

    if (!isOffline && !isStale) return const SizedBox.shrink();

    return MaterialBanner(
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      leading: Icon(
        isOffline ? Icons.cloud_off : Icons.sync_problem,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      content: Text(
        isOffline
            ? 'Modalità offline - Visualizzazione dati locali'
            : 'Dati potrebbero non essere aggiornati - Sincronizzazione in corso',
      ),
      actions: [
        if (!isOffline)
          TextButton(
            onPressed: () => ref.refresh(incomeSourcesListProvider),
            child: const Text('AGGIORNA'),
          ),
      ],
    );
  }
}
```

**Alternatives Considered**:
- Toast messages - Rejected: Temporary and easy to miss
- Snackbar - Rejected: Blocks bottom navigation
- Status badge on dashboard card - Rejected: Less visible

---

### 6. State Machine for Reimbursement Status Transitions

**Decision**: Implement validation in `ExpenseEntity` with confirmation required for reimbursed → reimbursable

**Rationale**:
- Domain logic belongs in entity layer (clean architecture)
- Prevents invalid state transitions at business logic level
- Confirmation dialog handled in presentation layer
- Type-safe with enum

**State Machine**:
```dart
// lib/features/expenses/domain/entities/expense_entity.dart (MODIFIED)

class ExpenseEntity {
  // ... existing fields ...
  final ReimbursementStatus reimbursementStatus;
  final DateTime? reimbursedAt;

  // Validation method for state transitions
  bool canTransitionTo(ReimbursementStatus newStatus) {
    switch (reimbursementStatus) {
      case ReimbursementStatus.none:
        return newStatus == ReimbursementStatus.reimbursable;

      case ReimbursementStatus.reimbursable:
        return newStatus == ReimbursementStatus.reimbursed ||
               newStatus == ReimbursementStatus.none;

      case ReimbursementStatus.reimbursed:
        // Reverting from reimbursed requires confirmation (handled in UI layer)
        return newStatus == ReimbursementStatus.reimbursable ||
               newStatus == ReimbursementStatus.none;
    }
  }

  // Check if confirmation is required for this transition
  bool requiresConfirmation(ReimbursementStatus newStatus) {
    return reimbursementStatus == ReimbursementStatus.reimbursed &&
           newStatus != ReimbursementStatus.reimbursed;
  }

  // Create updated entity with new reimbursement status
  ExpenseEntity updateReimbursementStatus(ReimbursementStatus newStatus) {
    return copyWith(
      reimbursementStatus: newStatus,
      reimbursedAt: newStatus == ReimbursementStatus.reimbursed
          ? DateTime.now()
          : null,
    );
  }
}
```

**Allowed Transitions**:
```
none → reimbursable (mark as pending reimbursement)
reimbursable → reimbursed (received reimbursement)
reimbursable → none (cancel reimbursement request)
reimbursed → reimbursable (undo reimbursement - requires confirmation)
reimbursed → none (undo reimbursement - requires confirmation)
```

**Alternatives Considered**:
- Free-form status changes - Rejected: No business rule enforcement
- Server-side only validation - Rejected: Delayed feedback to user
- State pattern with classes - Rejected: Overkill for 3 states

---

### 7. Flutter Widget Testing Best Practices

**Decision**: Use flutter_test with golden tests for dialogs + integration tests for flows

**Rationale**:
- Matches existing test patterns in codebase
- Golden tests ensure visual regression detection
- Integration tests validate E2E flows
- Mockito for provider mocking

**Test Pattern**:
```dart
// test/features/expenses/presentation/widgets/delete_confirmation_dialog_test.dart

void main() {
  group('DeleteConfirmationDialog', () {
    testWidgets('shows warning for reimbursable expense', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDeleteConfirmationDialog(
                  context,
                  isReimbursable: true,
                  expenseName: 'Test Expense',
                ),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify warning text appears
      expect(
        find.text('Attenzione: questa spesa è in attesa di rimborso.'),
        findsOneWidget,
      );

      // Verify buttons exist
      expect(find.text('Annulla'), findsOneWidget);
      expect(find.text('Elimina'), findsOneWidget);
    });

    testWidgets('returns true when confirm is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDeleteConfirmationDialog(
                    context,
                    isReimbursable: false,
                    expenseName: 'Test',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}
```

**Alternatives Considered**:
- Screenshot tests only - Rejected: Don't verify behavior
- Manual testing - Rejected: Not automated/repeatable
- Appium/Detox - Rejected: Overkill for Flutter (flutter_driver sufficient)

---

## Research Summary

All technical unknowns resolved. Ready to proceed to Phase 1 (Design & Contracts).

**Key Decisions**:
1. Material AlertDialog for confirmations (existing pattern)
2. Two-field schema extension (reimbursement_status enum + reimbursed_at timestamp)
3. Budget calculator treats reimbursements as income in reimbursement period
4. FutureProvider pattern ensures income loads before dashboard renders
5. Extend offline_banner.dart for stale data indication
6. Domain-level state machine validation with UI-level confirmation prompts
7. flutter_test + golden tests + integration tests for comprehensive coverage

**No Blockers**: All implementation patterns align with existing codebase architecture.
