# Data Model: Expense Management Improvements

**Feature**: 012-expense-improvements
**Date**: 2026-01-16
**Purpose**: Define entity extensions, relationships, and validation rules

## Phase 1: Data Model Design

### 1. Expense Entity Extension

**File**: `lib/features/expenses/domain/entities/expense_entity.dart`

#### New Fields

| Field | Type | Nullable | Default | Description |
|-------|------|----------|---------|-------------|
| `reimbursementStatus` | `ReimbursementStatus` | No | `none` | Current reimbursement state |
| `reimbursedAt` | `DateTime` | Yes | `null` | When expense was marked as reimbursed |

#### Updated Entity Definition

```dart
class ExpenseEntity extends Equatable {
  // === Existing Fields ===
  final String id;
  final String groupId;
  final String createdBy;
  final double amount;            // EUR with cents precision
  final DateTime date;            // Original expense date
  final String? categoryId;
  final String? categoryName;
  final String paymentMethodId;
  final String? paymentMethodName;
  final bool isGroupExpense;
  final String? merchant;
  final String? notes;
  final String? receiptUrl;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // === NEW Fields ===
  final ReimbursementStatus reimbursementStatus;
  final DateTime? reimbursedAt;   // Period assignment for budget calc

  const ExpenseEntity({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.amount,
    required this.date,
    this.categoryId,
    this.categoryName,
    required this.paymentMethodId,
    this.paymentMethodName,
    required this.isGroupExpense,
    this.merchant,
    this.notes,
    this.receiptUrl,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.reimbursementStatus = ReimbursementStatus.none,
    this.reimbursedAt,
  });

  // === Computed Properties ===

  /// Formatted amount in EUR with 2 decimal places
  String get formattedAmount => '€${amount.toStringAsFixed(2)}';

  /// Whether this expense has a receipt uploaded
  bool get hasReceipt => receiptUrl != null && receiptUrl!.isNotEmpty;

  /// Whether this expense is pending reimbursement
  bool get isPendingReimbursement =>
      reimbursementStatus == ReimbursementStatus.reimbursable;

  /// Whether this expense has been reimbursed
  bool get isReimbursed =>
      reimbursementStatus == ReimbursementStatus.reimbursed;

  /// Human-readable reimbursement status label (Italian)
  String get reimbursementStatusLabel => reimbursementStatus.label;

  // === State Transition Validation ===

  /// Check if transition to new status is allowed by business rules
  bool canTransitionTo(ReimbursementStatus newStatus) {
    switch (reimbursementStatus) {
      case ReimbursementStatus.none:
        return newStatus == ReimbursementStatus.reimbursable;

      case ReimbursementStatus.reimbursable:
        return newStatus == ReimbursementStatus.reimbursed ||
               newStatus == ReimbursementStatus.none;

      case ReimbursementStatus.reimbursed:
        // Can revert, but requires confirmation in UI layer
        return newStatus == ReimbursementStatus.reimbursable ||
               newStatus == ReimbursementStatus.none;
    }
  }

  /// Check if confirmation dialog is required for this transition
  bool requiresConfirmation(ReimbursementStatus newStatus) {
    return reimbursementStatus == ReimbursementStatus.reimbursed &&
           newStatus != ReimbursementStatus.reimbursed;
  }

  // === Entity Updates ===

  /// Create updated entity with new reimbursement status
  ExpenseEntity updateReimbursementStatus(ReimbursementStatus newStatus) {
    if (!canTransitionTo(newStatus)) {
      throw StateError(
        'Invalid transition from $reimbursementStatus to $newStatus',
      );
    }

    return copyWith(
      reimbursementStatus: newStatus,
      reimbursedAt: newStatus == ReimbursementStatus.reimbursed
          ? DateTime.now()  // Capture timestamp for period-based budget calc
          : null,           // Clear timestamp if reverting
      updatedAt: DateTime.now(),
    );
  }

  // === Permissions ===

  /// Check if user can edit this expense
  bool canEdit(String userId, bool isAdmin) {
    return isAdmin || createdBy == userId;
  }

  /// Check if user can delete this expense
  bool canDelete(String userId, bool isAdmin) {
    return canEdit(userId, isAdmin);
  }

  /// Check if user can change reimbursement status
  bool canChangeReimbursementStatus(String userId, bool isAdmin) {
    return canEdit(userId, isAdmin);
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        createdBy,
        amount,
        date,
        categoryId,
        categoryName,
        paymentMethodId,
        paymentMethodName,
        isGroupExpense,
        merchant,
        notes,
        receiptUrl,
        createdByName,
        createdAt,
        updatedAt,
        reimbursementStatus,
        reimbursedAt,
      ];
}
```

#### Validation Rules

| Rule | Validation | Error Message |
|------|-----------|---------------|
| **R1** | `amount > 0` | "L'importo deve essere maggiore di zero" |
| **R2** | `reimbursedAt == null OR reimbursementStatus == reimbursed` | "La data di rimborso richiede status 'rimborsato'" |
| **R3** | `reimbursedAt != null IF reimbursementStatus == reimbursed` | "Status 'rimborsato' richiede data di rimborso" |
| **R4** | `canTransitionTo(newStatus) == true` | "Transizione di stato non valida" |
| **R5** | `date <= reimbursedAt IF reimbursedAt != null` | "Data rimborso non può precedere data spesa" |

---

### 2. Reimbursement Status Enum

**File**: `lib/core/enums/reimbursement_status.dart`

```dart
/// Reimbursement status for expenses
///
/// State machine transitions:
/// - none → reimbursable (mark as pending)
/// - reimbursable → reimbursed (received money back)
/// - reimbursable → none (cancel reimbursement)
/// - reimbursed → reimbursable (undo - requires confirmation)
/// - reimbursed → none (undo - requires confirmation)
enum ReimbursementStatus {
  /// Regular expense with no reimbursement expected
  none('none', 'Nessun rimborso'),

  /// Expense awaiting reimbursement
  reimbursable('reimbursable', 'Da rimborsare'),

  /// Expense that has been reimbursed
  reimbursed('reimbursed', 'Rimborsato');

  const ReimbursementStatus(this.value, this.label);

  /// Database value (stored in Supabase/Drift)
  final String value;

  /// Human-readable Italian label for UI display
  final String label;

  /// Parse from database string value
  static ReimbursementStatus fromString(String value) {
    return ReimbursementStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReimbursementStatus.none,
    );
  }

  /// Get icon for this status
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

  /// Get color for this status (using Material 3 palette)
  Color getColor(ColorScheme colorScheme) {
    switch (this) {
      case ReimbursementStatus.none:
        return colorScheme.onSurface;
      case ReimbursementStatus.reimbursable:
        return colorScheme.tertiary;  // Amber/Honey color
      case ReimbursementStatus.reimbursed:
        return colorScheme.primary;   // Sage Green
    }
  }
}
```

---

### 3. Budget Stats Entity Extension

**File**: `lib/features/budgets/domain/entities/budget_stats_entity.dart`

#### New Fields

| Field | Type | Description |
|-------|------|-------------|
| `totalPendingReimbursements` | `int` | Sum of expenses with status "reimbursable" |
| `totalReimbursedIncome` | `int` | Sum of reimbursed amounts in this period |

```dart
class BudgetStatsEntity extends Equatable {
  // === Existing Fields ===
  final int spentAmount;         // Total expenses (whole euros, rounded up)
  final bool isOverBudget;       // spentAmount >= budgetAmount
  final bool isNearLimit;        // spentAmount >= budgetAmount * 0.8
  final int expenseCount;        // Number of expenses

  // === NEW Fields ===
  final int totalPendingReimbursements;  // Awaiting reimbursement
  final int totalReimbursedIncome;       // Already reimbursed (this period)

  const BudgetStatsEntity({
    required this.spentAmount,
    required this.isOverBudget,
    required this.isNearLimit,
    required this.expenseCount,
    this.totalPendingReimbursements = 0,
    this.totalReimbursedIncome = 0,
  });

  /// Net spending after accounting for reimbursements
  int get netSpentAmount => spentAmount - totalReimbursedIncome;

  /// Whether net spending exceeds budget
  bool isNetOverBudget(int budgetAmount) => netSpentAmount >= budgetAmount;

  /// Whether net spending is near budget limit (80%)
  bool isNetNearLimit(int budgetAmount) =>
      netSpentAmount >= (budgetAmount * 0.8).ceil();

  @override
  List<Object?> get props => [
        spentAmount,
        isOverBudget,
        isNearLimit,
        expenseCount,
        totalPendingReimbursements,
        totalReimbursedIncome,
      ];
}
```

---

### 4. Reimbursement Summary Entity (NEW)

**File**: `lib/features/budgets/domain/entities/reimbursement_summary_entity.dart`

```dart
/// Summary of reimbursement statistics for budget overview
class ReimbursementSummaryEntity extends Equatable {
  /// Total amount pending reimbursement (awaiting payment)
  final int pendingAmount;

  /// Total amount reimbursed in current period
  final int reimbursedAmount;

  /// Number of expenses awaiting reimbursement
  final int pendingCount;

  /// Number of expenses reimbursed in current period
  final int reimbursedCount;

  const ReimbursementSummaryEntity({
    required this.pendingAmount,
    required this.reimbursedAmount,
    required this.pendingCount,
    required this.reimbursedCount,
  });

  /// Whether there are any pending reimbursements
  bool get hasPendingReimbursements => pendingCount > 0;

  /// Whether there were any reimbursements this period
  bool get hasReimbursements => reimbursedCount > 0;

  /// Formatted pending amount in EUR
  String get formattedPendingAmount => '€${pendingAmount.toStringAsFixed(2)}';

  /// Formatted reimbursed amount in EUR
  String get formattedReimbursedAmount => '€${reimbursedAmount.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
        pendingAmount,
        reimbursedAmount,
        pendingCount,
        reimbursedCount,
      ];
}
```

---

### 5. Database Schema Changes

#### Supabase Table: `public.expenses`

**Migration SQL**:
```sql
-- Migration: 20260116_add_reimbursement_tracking.sql

-- Add reimbursement columns
ALTER TABLE public.expenses
ADD COLUMN reimbursement_status TEXT DEFAULT 'none' NOT NULL
  CHECK (reimbursement_status IN ('none', 'reimbursable', 'reimbursed')),
ADD COLUMN reimbursed_at TIMESTAMPTZ DEFAULT NULL;

-- Add constraint: reimbursed_at required when status is reimbursed
ALTER TABLE public.expenses
ADD CONSTRAINT check_reimbursed_at_consistency
  CHECK (
    (reimbursement_status = 'reimbursed' AND reimbursed_at IS NOT NULL) OR
    (reimbursement_status != 'reimbursed' AND reimbursed_at IS NULL)
  );

-- Add index for filtering by reimbursement status (partial index for efficiency)
CREATE INDEX idx_expenses_reimbursement_status
  ON public.expenses(reimbursement_status)
  WHERE reimbursement_status != 'none';

-- Add index for period-based reimbursement queries
CREATE INDEX idx_expenses_reimbursed_at
  ON public.expenses(reimbursed_at)
  WHERE reimbursed_at IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.expenses.reimbursement_status IS
  'Reimbursement tracking: none (default), reimbursable (awaiting), reimbursed (received)';

COMMENT ON COLUMN public.expenses.reimbursed_at IS
  'Timestamp when expense was marked as reimbursed. Used for period-based budget calculations. NULL if not reimbursed.';

-- Update existing expenses to have default values
UPDATE public.expenses
SET reimbursement_status = 'none'
WHERE reimbursement_status IS NULL;
```

**Rollback SQL**:
```sql
-- Rollback: 20260116_add_reimbursement_tracking_down.sql

DROP INDEX IF EXISTS idx_expenses_reimbursement_status;
DROP INDEX IF EXISTS idx_expenses_reimbursed_at;

ALTER TABLE public.expenses
DROP CONSTRAINT IF EXISTS check_reimbursed_at_consistency;

ALTER TABLE public.expenses
DROP COLUMN IF EXISTS reimbursement_status,
DROP COLUMN IF EXISTS reimbursed_at;
```

#### Drift Local Schema

**File**: `lib/core/database/drift/tables/expenses.dart`

```dart
// Add to existing Expenses table definition

class Expenses extends Table {
  // ... existing columns ...

  // NEW: Reimbursement tracking
  TextColumn get reimbursementStatus => text()
      .withDefault(const Constant('none'))
      .check(reimbursementStatus.isIn(['none', 'reimbursable', 'reimbursed']))();

  DateTimeColumn get reimbursedAt => dateTime().nullable()();
}
```

---

### 6. Entity Relationships

```
ExpenseEntity
  ├─ reimbursementStatus: ReimbursementStatus (enum)
  ├─ reimbursedAt: DateTime? (nullable, set when status = reimbursed)
  └─ Affects:
      ├─ BudgetStatsEntity.totalReimbursedIncome (if reimbursed in period)
      ├─ BudgetStatsEntity.totalPendingReimbursements (if reimbursable)
      └─ ReimbursementSummaryEntity (aggregated stats)

BudgetStatsEntity
  ├─ totalPendingReimbursements: int (sum of reimbursable expenses)
  ├─ totalReimbursedIncome: int (sum of reimbursed in period)
  └─ netSpentAmount: int (spentAmount - totalReimbursedIncome)

ReimbursementSummaryEntity
  ├─ pendingAmount: int (from reimbursable expenses)
  ├─ reimbursedAmount: int (from reimbursed expenses in period)
  ├─ pendingCount: int
  └─ reimbursedCount: int
```

---

### 7. Data Flow Diagram

```
User Action: Mark Expense as Reimbursable
  ↓
ExpenseEntity.updateReimbursementStatus(ReimbursementStatus.reimbursable)
  ├─ Validates transition with canTransitionTo()
  ├─ Creates new entity with updated status
  └─ reimbursedAt remains null
  ↓
ExpenseRepository.updateExpense()
  ├─ Persists to Supabase
  └─ Syncs to Drift local DB
  ↓
Riverpod Provider Invalidation
  ├─ expenseListProvider refreshes
  ├─ budgetStatsProvider recalculates
  │   └─ totalPendingReimbursements updated
  └─ reimbursementSummaryProvider refreshes
  ↓
UI Updates
  ├─ Expense list shows "Da rimborsare" badge
  ├─ Budget overview shows pending total
  └─ Filter includes reimbursable option

---

User Action: Mark Expense as Reimbursed
  ↓
ExpenseEntity.updateReimbursementStatus(ReimbursementStatus.reimbursed)
  ├─ Validates transition
  ├─ Sets reimbursedAt = DateTime.now()  ← CRITICAL for period assignment
  └─ Creates new entity
  ↓
ExpenseRepository.updateExpense()
  ↓
Riverpod Provider Invalidation
  ├─ budgetStatsProvider recalculates
  │   ├─ totalReimbursedIncome updated (if in current period)
  │   ├─ totalPendingReimbursements decreased
  │   └─ netSpentAmount = spentAmount - totalReimbursedIncome
  └─ reimbursementSummaryProvider refreshes
  ↓
UI Updates
  ├─ Expense shows "Rimborsato" badge with green checkmark
  ├─ Budget remaining increases (reimbursement added as income)
  └─ Reimbursement summary shows reimbursed count/amount
```

---

## Data Integrity Rules

### Invariants

1. **Reimbursed Timestamp Consistency**:
   - `reimbursement_status == 'reimbursed' ⟺ reimbursed_at IS NOT NULL`
   - Enforced by database constraint + entity validation

2. **State Transition Validity**:
   - All transitions must pass `canTransitionTo()` check
   - Invalid transitions throw `StateError` in domain layer

3. **Chronological Ordering**:
   - `expense.date <= expense.reimbursedAt` (if reimbursed)
   - Reimbursement cannot precede expense creation

4. **Period Assignment**:
   - Reimbursed income counts toward period of `reimbursedAt`, NOT `expense.date`
   - Ensures accurate monthly/yearly budget calculations

5. **Budget Calculation Accuracy**:
   - `netSpentAmount = spentAmount - totalReimbursedIncome`
   - `remainingBudget = budgetAmount - netSpentAmount`
   - Both amounts rounded to whole euros (ceiling function)

---

## Migration Strategy

### Phase 1: Schema Migration
1. Run Supabase SQL migration (add columns with defaults)
2. All existing expenses get `reimbursement_status = 'none'`
3. No data loss (backwards compatible)

### Phase 2: Dart Code Updates
1. Update `ExpenseEntity` with new fields
2. Update `ExpenseModel` JSON serialization
3. Update Drift table definition
4. Generate Drift code: `flutter pub run build_runner build`

### Phase 3: UI Updates
1. Add reimbursement toggle to expense forms
2. Add status badges to expense list items
3. Add reimbursement summary to budget dashboard

### Phase 4: Testing
1. Unit tests for entity state machine
2. Integration tests for database migrations
3. Widget tests for new UI components
4. E2E tests for reimbursement workflows

---

**Next**: Generate API contracts (if needed) and quickstart documentation.
