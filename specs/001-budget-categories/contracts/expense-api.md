# Expense API Extensions Contract

**Feature**: Budget Management and Category Customization
**Version**: 1.0.0
**Date**: 2025-12-31

## Overview

This document defines the API extensions to the existing expense operations to support:
1. Group/Personal expense classification (`is_group_expense` flag)
2. Category reference (`category_id` foreign key)
3. Migration of existing expenses

**Note**: This extends the existing expense API, not a replacement. Base expense operations (create, read, update, delete) remain unchanged except for the new fields.

## Modified Operations

### 1. Create Expense (Modified)

**Changes**: Add `isGroupExpense` and `categoryId` fields

**Request** (additions only):
```dart
class CreateExpenseRequest {
  // ... existing fields (amount, date, store, etc.)

  final bool isGroupExpense;     // NEW: Default true
  final String categoryId;       // NEW: FK to expense_categories
}
```

**Response**:
```dart
class ExpenseResponse {
  // ... existing fields

  final bool isGroupExpense;     // NEW
  final String categoryId;       // NEW
  final String categoryName;     // NEW: Denormalized for display
}
```

**Database Operation**:
```sql
INSERT INTO expenses (
  created_by, group_id, amount, date, store, receipt_image_url,
  is_group_expense, category_id
)
VALUES (
  auth.uid(), $1, $2, $3, $4, $5,
  COALESCE($6, true), $7  -- Default to group expense if not specified
)
RETURNING *;
```

**Validation**:
- categoryId must exist and belong to user's group
- isGroupExpense defaults to true if not specified

---

### 2. Update Expense Classification

**Operation**: `updateExpenseClassification`
**Description**: Change an expense from group to personal or vice versa
**Authorization**: Must be expense creator

**Request**:
```dart
class UpdateExpenseClassificationRequest {
  final String expenseId;
  final bool isGroupExpense;  // New classification
}
```

**Response**:
```dart
class ExpenseResponse {
  // Full expense object with updated classification
}
```

**Database Operation**:
```sql
UPDATE expenses
SET
  is_group_expense = $2,
  updated_at = now()
WHERE id = $1
  AND created_by = auth.uid()  -- Only creator can reclassify
RETURNING *;
```

**Errors**:
- `PermissionDeniedFailure`: User is not expense creator
- `NotFoundFailure`: Expense doesn't exist

**Side Effects** (handled in application layer):
- Budget stats for affected user(s) must be recalculated
- If changing from group to personal: removed from group dashboard
- If changing from personal to group: added to group dashboard
- Triggers Riverpod state update for real-time UI refresh

---

### 3. Update Expense Category

**Operation**: `updateExpenseCategory`
**Description**: Change the category of an expense
**Authorization**: Must be expense creator

**Request**:
```dart
class UpdateExpenseCategoryRequest {
  final String expenseId;
  final String newCategoryId;
}
```

**Response**:
```dart
class ExpenseResponse {
  // Full expense object with updated category
}
```

**Database Operation**:
```sql
UPDATE expenses
SET
  category_id = $2,
  updated_at = now()
WHERE id = $1
  AND created_by = auth.uid()
RETURNING *;
```

**Validation**:
- newCategoryId must exist and belong to user's group

**Errors**:
- `PermissionDeniedFailure`: User is not expense creator
- `ValidationFailure`: Invalid category ID or category doesn't belong to group
- `NotFoundFailure`: Expense doesn't exist

---

### 4. Get Expenses (Modified)

**Changes**: Support filtering by expense type and category

**Request** (additions only):
```dart
class GetExpensesRequest {
  // ... existing fields (groupId, userId, startDate, endDate, etc.)

  final ExpenseTypeFilter? typeFilter;  // NEW
  final String? categoryId;             // NEW: Filter by category
}

enum ExpenseTypeFilter {
  ALL,              // Both group and personal (default)
  GROUP_ONLY,       // Only group expenses
  PERSONAL_ONLY,    // Only personal expenses
}
```

**Response**:
```dart
class ExpensesListResponse {
  final List<ExpenseResponse> expenses;
}

class ExpenseResponse {
  // ... existing fields
  final bool isGroupExpense;
  final String categoryId;
  final String categoryName;
  final bool isOwnExpense;  // NEW: true if created by current user
}
```

**Database Operation**:
```sql
SELECT
  e.*,
  c.name as category_name,
  (e.created_by = auth.uid()) as is_own_expense
FROM expenses e
LEFT JOIN expense_categories c ON e.category_id = c.id
WHERE e.group_id = $1
  AND ($2::DATE IS NULL OR e.date >= $2)
  AND ($3::DATE IS NULL OR e.date <= $3)
  AND (
    $4 = 'ALL'
    OR ($4 = 'GROUP_ONLY' AND e.is_group_expense = true)
    OR ($4 = 'PERSONAL_ONLY' AND e.is_group_expense = false AND e.created_by = auth.uid())
  )
  AND ($5::UUID IS NULL OR e.category_id = $5)
ORDER BY e.date DESC, e.created_at DESC
LIMIT $6 OFFSET $7;
```

**RLS Impact**:
- Personal expenses (is_group_expense=false) automatically filtered by RLS
- Only creator can see their own personal expenses
- Group expenses visible to all group members

---

### 5. Bulk Update Category (Admin Only)

**Operation**: `bulkUpdateExpenseCategory`
**Description**: Reassign multiple expenses to a new category (used during category deletion)
**Authorization**: Must be group administrator

**Request**:
```dart
class BulkUpdateExpenseCategoryRequest {
  final String groupId;
  final List<String> expenseIds;     // Expenses to update
  final String newCategoryId;        // Target category
}
```

**Response**:
```dart
class BulkUpdateCategoryResponse {
  final int updatedCount;
  final List<String> failedExpenseIds;  // If some updates failed
}
```

**Database Operation**:
```sql
UPDATE expenses
SET
  category_id = $3,
  updated_at = now()
WHERE id = ANY($2::UUID[])
  AND group_id = $1
  AND EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid()
      AND group_id = $1
      AND is_group_admin = true
  )
RETURNING id;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group administrator
- `ValidationFailure`: Invalid category ID
- `PartialFailure`: Some expenses updated, some failed (returns partial results)

**Use Case**:
- Called during category deletion with reassignment
- Efficiently updates hundreds of expenses in one transaction

---

## New Operations

### 6. Migrate Existing Expenses

**Operation**: `migrateExpensesToNewSchema`
**Description**: One-time migration to add is_group_expense=true to all existing expenses
**Authorization**: System/internal (not exposed to user-facing API)

**Request**:
```dart
class MigrateExpensesRequest {
  final String? groupId;  // Optional: migrate specific group or all
}
```

**Response**:
```dart
class MigrationResponse {
  final int totalExpenses;
  final int migratedExpenses;
  final List<String> errors;
}
```

**Database Operation**:
```sql
-- Add column with default (if not already added)
ALTER TABLE expenses
ADD COLUMN IF NOT EXISTS is_group_expense BOOLEAN NOT NULL DEFAULT true;

-- Verify all rows have the value
UPDATE expenses
SET is_group_expense = true
WHERE is_group_expense IS NULL
  AND ($1::UUID IS NULL OR group_id = $1);

-- Category migration (separate operation)
-- Map old string 'category' to new category_id
UPDATE expenses e
SET category_id = (
  SELECT c.id
  FROM expense_categories c
  WHERE c.group_id = e.group_id
    AND LOWER(c.name) = LOWER(e.category)
  LIMIT 1
)
WHERE e.category_id IS NULL
  AND e.category IS NOT NULL;

-- Fallback: Assign unmapped expenses to "Other"
UPDATE expenses e
SET category_id = (
  SELECT c.id
  FROM expense_categories c
  WHERE c.group_id = e.group_id
    AND c.name = 'Other'
  LIMIT 1
)
WHERE e.category_id IS NULL;
```

**Testing**:
- Run on staging environment first
- Verify all expenses have is_group_expense=true
- Verify all expenses have valid category_id
- Spot-check category mappings are correct

**Rollback**:
- Restore from backup
- Or: Keep old 'category' column until migration verified

---

### 7. Get Expense Stats by Type

**Operation**: `getExpenseStatsByType`
**Description**: Get aggregated stats split by group vs personal expenses
**Authorization**: Must be group member (for group stats) or own user (for personal stats)

**Request**:
```dart
class GetExpenseStatsByTypeRequest {
  final String? groupId;     // For group stats
  final String? userId;      // For personal stats
  final int month;
  final int year;
}
```

**Response**:
```dart
class ExpenseStatsByTypeResponse {
  final ExpenseTypeStats groupExpenses;
  final ExpenseTypeStats personalExpenses;
  final ExpenseTypeStats total;
}

class ExpenseTypeStats {
  final int count;
  final double totalAmount;
  final double averageAmount;
}
```

**Database Operation**:
```sql
SELECT
  e.is_group_expense,
  COUNT(*) as count,
  COALESCE(SUM(e.amount), 0) as total_amount,
  COALESCE(AVG(e.amount), 0) as average_amount
FROM expenses e
WHERE ($1::UUID IS NULL OR e.group_id = $1)
  AND ($2::UUID IS NULL OR e.created_by = $2)
  AND EXTRACT(YEAR FROM e.date) = $3
  AND EXTRACT(MONTH FROM e.date) = $4
GROUP BY e.is_group_expense;
```

**Use Case**:
- Dashboard analytics showing spending breakdown
- Personal dashboard showing "X% of spending is group, Y% is personal"

---

## Privacy & RLS Updates

### New RLS Policies for Personal Expenses

**Policy 1: View Group Expenses**
```sql
CREATE POLICY "Users can view group expenses in their group"
  ON expenses FOR SELECT
  USING (
    is_group_expense = true
    AND group_id IN (
      SELECT group_id FROM profiles WHERE id = auth.uid()
    )
  );
```

**Policy 2: View Own Personal Expenses**
```sql
CREATE POLICY "Users can view their own personal expenses"
  ON expenses FOR SELECT
  USING (
    is_group_expense = false
    AND created_by = auth.uid()
  );
```

**Policy 3: Create Expenses**
```sql
CREATE POLICY "Users can create expenses in their group"
  ON expenses FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND group_id IN (
      SELECT group_id FROM profiles WHERE id = auth.uid()
    )
  );
```

**Policy 4: Update Own Expenses**
```sql
CREATE POLICY "Users can update their own expenses"
  ON expenses FOR UPDATE
  USING (created_by = auth.uid());
```

**Policy 5: Delete Per Original Rules**
```sql
-- Creator can delete own expenses
CREATE POLICY "Users can delete their own expenses"
  ON expenses FOR DELETE
  USING (created_by = auth.uid());

-- Group admin can delete any group expense (NOT personal expenses)
CREATE POLICY "Admins can delete group expenses"
  ON expenses FOR DELETE
  USING (
    is_group_expense = true
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = expenses.group_id
        AND is_group_admin = true
    )
  );
```

---

## Validation Rules

### Expense Classification

**Rule 1**: Default to group expense
```dart
final isGroupExpense = request.isGroupExpense ?? true;
```

**Rule 2**: User must be in a group to create group expenses
```dart
if (isGroupExpense && user.groupId == null) {
  throw ValidationFailure('Cannot create group expense without being in a group');
}
```

**Rule 3**: Category must belong to user's group
```dart
final category = await categoryRepository.getById(request.categoryId);
if (category.groupId != user.groupId) {
  throw ValidationFailure('Category does not belong to your group');
}
```

---

## Performance Requirements

- Update classification: < 200ms p95
- Bulk category update (500 expenses): < 1s p95
- Get expenses with filters: < 300ms p95
- Migration (10,000 expenses): < 30s total

---

## Testing Strategy

### Unit Tests
- Test is_group_expense defaults to true
- Test RLS prevents cross-user access to personal expenses
- Test category validation on create/update
- Test bulk update transaction rollback on partial failure

### Integration Tests
1. Create expense as group (default) - visible to all group members
2. Create expense as personal - visible only to creator
3. Admin cannot view other member's personal expense
4. Change expense from group to personal - disappears from other members' views
5. Change expense from personal to group - appears in group dashboard
6. Update category - expense shows new category name
7. Bulk update during category deletion - all expenses reassigned
8. Migration - all existing expenses have is_group_expense=true

### Edge Cases
- Concurrent classification updates - last write wins
- Reclassify expense while another user viewing group dashboard - real-time update
- Delete category while expense being created with that category - graceful error

---

## Backward Compatibility

**Old App Versions** (without budget feature):
- Can still create expenses (is_group_expense defaults to true)
- Category field migration ensures old expenses work
- No UI for classification, but expenses still function

**New App Versions**:
- Support both classified and unclassified expenses gracefully
- Show "Group" indicator on group expenses
- Show lock icon on personal expenses

---

## Migration Timeline

1. **Phase 1** (Day 1): Deploy schema changes
   - Add is_group_expense column with default
   - Add category_id column (nullable)
   - Update RLS policies

2. **Phase 2** (Day 2-3): Background migration
   - Set is_group_expense=true for all existing
   - Map old category strings to new IDs
   - Monitor for errors

3. **Phase 3** (Day 7): Verification
   - Verify all expenses have correct flags
   - Verify category mappings
   - Spot-check random samples

4. **Phase 4** (Day 14): Cleanup
   - Drop old category column
   - Make category_id NOT NULL if desired

---

## Future Enhancements

- Split group expenses (expense shared by subset of group)
- Recurring expense templates with classification
- Expense approval workflow (for group expenses)
- Expense splitting (one expense, multiple categories)
