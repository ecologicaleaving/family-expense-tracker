# Category API Contract

**Feature**: Budget Management and Category Customization
**Version**: 1.0.0
**Date**: 2025-12-31

## Overview

This document defines the API contract for expense category management operations. Categories are group-scoped and managed exclusively by group administrators.

**Implementation Note**: Operations implemented as Dart repository methods using Supabase client SDK with Row Level Security (RLS) enforcement.

## Operations

### 1. List Categories

**Operation**: `listCategories`
**Description**: Get all expense categories for the user's group (default + custom)
**Authorization**: Must be group member

**Request**:
```dart
class ListCategoriesRequest {
  final String groupId;
  final bool? includeDefaults;  // Optional: filter to only defaults or only custom
}
```

**Response**:
```dart
class CategoryListResponse {
  final List<ExpenseCategoryResponse> categories;
}

class ExpenseCategoryResponse {
  final String id;
  final String name;
  final String groupId;
  final bool isDefault;
  final String? createdBy;    // null for default categories
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? expenseCount;    // Optional: number of expenses using this category
}
```

**Database Operation**:
```sql
SELECT
  c.*,
  COUNT(e.id) as expense_count
FROM expense_categories c
LEFT JOIN expenses e ON e.category_id = c.id
WHERE c.group_id = $1
  AND ($2::BOOLEAN IS NULL OR c.is_default = $2)
GROUP BY c.id
ORDER BY c.is_default DESC, c.name ASC;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group member

**Notes**:
- Default categories appear first, then custom alphabetically
- expenseCount useful for showing usage and preventing deletion of in-use categories

---

### 2. Create Category

**Operation**: `createCategory`
**Description**: Create a new custom expense category (admin only)
**Authorization**: Must be group administrator

**Request**:
```dart
class CreateCategoryRequest {
  final String groupId;
  final String name;        // 1-50 characters, trimmed
}
```

**Response**:
```dart
class ExpenseCategoryResponse {
  // Same as list response
}
```

**Database Operation**:
```sql
INSERT INTO expense_categories (group_id, name, is_default, created_by)
VALUES ($1, TRIM($2), false, auth.uid())
RETURNING *;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group administrator
- `ValidationFailure`: Invalid name (empty, too long, whitespace only)
- `ConflictFailure`: Category name already exists in group (case-insensitive)

**Validation Rules**:
- name length: 1-50 characters after trim
- name must not be empty or whitespace-only
- name must be unique within group (case-insensitive check recommended)
- no leading/trailing whitespace (automatically trimmed)

---

### 3. Update Category

**Operation**: `updateCategory`
**Description**: Update an existing category's name (admin only, custom categories only)
**Authorization**: Must be group administrator

**Request**:
```dart
class UpdateCategoryRequest {
  final String categoryId;
  final String newName;     // 1-50 characters, trimmed
}
```

**Response**:
```dart
class ExpenseCategoryResponse {
  // Same as list response
}
```

**Database Operation**:
```sql
UPDATE expense_categories
SET
  name = TRIM($2),
  updated_at = now()
WHERE id = $1
  AND is_default = false  -- Cannot update default categories
RETURNING *;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group administrator
- `ValidationFailure`: Invalid new name
- `ConflictFailure`: New name already exists in group
- `ForbiddenFailure`: Attempting to update default category

**Notes**:
- All expenses using this category automatically reflect the new name (FK relationship)
- Cannot rename default categories (Food, Utilities, etc.)

---

### 4. Delete Category

**Operation**: `deleteCategory`
**Description**: Delete a custom category with expense reassignment (admin only)
**Authorization**: Must be group administrator

**Request**:
```dart
class DeleteCategoryRequest {
  final String categoryId;
  final DeleteCategoryStrategy strategy;
  final String? reassignToCategoryId;  // Required if strategy is REASSIGN
}

enum DeleteCategoryStrategy {
  AUTO_MOVE_TO_OTHER,   // Move all expenses to "Other" category
  REASSIGN,             // Reassign to specific category
}
```

**Response**:
```dart
class DeleteCategoryResponse {
  final bool success;
  final int affectedExpenseCount;  // Number of expenses reassigned
  final String? reassignedTo;      // Category ID where expenses moved
}
```

**Database Operation (Multi-step Transaction)**:
```sql
BEGIN;

-- Step 1: Check if category has expenses
SELECT COUNT(*) as expense_count
FROM expenses
WHERE category_id = $1;

-- Step 2: If expenses exist, reassign them
UPDATE expenses
SET category_id = $2  -- reassignToCategoryId or "Other" category ID
WHERE category_id = $1;

-- Step 3: Delete the category
DELETE FROM expense_categories
WHERE id = $1
  AND is_default = false
RETURNING id;

COMMIT;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group administrator
- `ForbiddenFailure`: Attempting to delete default category
- `ValidationFailure`: REASSIGN strategy but reassignToCategoryId is null
- `NotFoundFailure`: Category or reassignment target doesn't exist
- `ConflictFailure`: Trying to reassign to the category being deleted

**Pre-check Operation** (called before showing confirmation dialog):
```dart
class CheckCategoryDeletionRequest {
  final String categoryId;
}

class CheckCategoryDeletionResponse {
  final bool canDelete;           // false if is_default
  final int expenseCount;         // number of expenses that would be affected
  final List<String> affectedExpenseIds;  // Optional: for preview
}
```

**UI Flow** (from spec):
1. User clicks delete on category
2. App calls checkCategoryDeletion
3. If expenseCount > 0, show warning dialog with:
   - "This category has X expenses"
   - Radio buttons: "Move to Other" / "Reassign to..."
   - If reassign: dropdown of available categories
4. User confirms
5. App calls deleteCategory with chosen strategy

---

### 5. Get Category Details

**Operation**: `getCategoryDetails`
**Description**: Get detailed information about a specific category
**Authorization**: Must be group member

**Request**:
```dart
class GetCategoryDetailsRequest {
  final String categoryId;
}
```

**Response**:
```dart
class CategoryDetailsResponse {
  final ExpenseCategoryResponse category;
  final int totalExpenseCount;
  final int currentMonthExpenseCount;
  final double totalAmount;           // Sum of all expenses in this category
  final double currentMonthAmount;    // Sum of this month's expenses
  final List<RecentExpense> recentExpenses;  // Last 5 expenses
}

class RecentExpense {
  final String id;
  final double amount;
  final DateTime date;
  final String createdByName;
}
```

**Database Operation**:
```sql
SELECT
  c.*,
  COUNT(e.id) as total_expense_count,
  COALESCE(SUM(e.amount), 0) as total_amount,
  COUNT(CASE
    WHEN EXTRACT(YEAR FROM e.date) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND EXTRACT(MONTH FROM e.date) = EXTRACT(MONTH FROM CURRENT_DATE)
    THEN 1
  END) as current_month_expense_count,
  COALESCE(SUM(CASE
    WHEN EXTRACT(YEAR FROM e.date) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND EXTRACT(MONTH FROM e.date) = EXTRACT(MONTH FROM CURRENT_DATE)
    THEN e.amount
  END), 0) as current_month_amount
FROM expense_categories c
LEFT JOIN expenses e ON e.category_id = c.id
WHERE c.id = $1
GROUP BY c.id;

-- Separate query for recent expenses
SELECT e.id, e.amount, e.date, p.name as created_by_name
FROM expenses e
JOIN profiles p ON e.created_by = p.id
WHERE e.category_id = $1
ORDER BY e.date DESC
LIMIT 5;
```

**Errors**:
- `PermissionDeniedFailure`: User is not in category's group
- `NotFoundFailure`: Category doesn't exist

**Use Case**:
- Shown when user taps on category in settings
- Helps decide whether to delete/rename category
- Shows impact of category

---

### 6. Seed Default Categories

**Operation**: `seedDefaultCategories`
**Description**: Create default categories for a new group (called automatically on group creation)
**Authorization**: System/internal operation (not exposed to direct user calls)

**Request**:
```dart
class SeedDefaultCategoriesRequest {
  final String groupId;
}
```

**Response**:
```dart
class SeedDefaultCategoriesResponse {
  final List<ExpenseCategoryResponse> categories;
}
```

**Database Operation**:
```sql
INSERT INTO expense_categories (group_id, name, is_default, created_by)
VALUES
  ($1, 'Food', true, NULL),
  ($1, 'Utilities', true, NULL),
  ($1, 'Transport', true, NULL),
  ($1, 'Healthcare', true, NULL),
  ($1, 'Entertainment', true, NULL),
  ($1, 'Other', true, NULL)
RETURNING *;
```

**Notes**:
- Called as part of group creation flow
- Default categories have is_default=true and created_by=NULL
- "Other" category is special: used as fallback for migration and reassignment

---

## Validation Rules

### Category Name Validation

Client-side pre-validation:
```dart
String? validateCategoryName(String name, List<String> existingNames) {
  final trimmed = name.trim();

  if (trimmed.isEmpty) {
    return 'Category name cannot be empty';
  }

  if (trimmed.length > 50) {
    return 'Category name must be 50 characters or less';
  }

  if (trimmed != name) {
    return 'Category name cannot have leading or trailing spaces';
  }

  if (existingNames.any((existing) =>
      existing.toLowerCase() == trimmed.toLowerCase())) {
    return 'A category with this name already exists';
  }

  return null; // Valid
}
```

Server-side validation (RLS + constraints):
- Enforced by CHECK constraints and UNIQUE index
- Case-insensitive uniqueness via functional index:
  ```sql
  CREATE UNIQUE INDEX idx_category_name_unique
  ON expense_categories (group_id, LOWER(name));
  ```

---

## Error Handling

**Failure Types**:
```dart
class ConflictFailure extends Failure {
  // Duplicate category name
}

class ForbiddenFailure extends Failure {
  // Attempting to modify default category
}

// Plus standard failures: ServerFailure, PermissionDeniedFailure, ValidationFailure, NotFoundFailure
```

---

## Performance Requirements

- List categories: < 100ms p95
- Create/update category: < 200ms p95
- Delete with reassignment: < 1s p95 (even with 500 expenses)
- Get category details: < 300ms p95

---

## Caching Strategy

**Client-Side (Drift)**:
- Cache full category list for group
- Invalidate on create/update/delete
- Background refresh every hour when online

**Why Cache Aggressively**:
- Categories change infrequently
- Needed for expense entry (offline support)
- Small data size (typically < 20 categories per group)

---

## Real-time Updates

**Supabase Realtime**:
```dart
supabase
  .from('expense_categories')
  .stream(primaryKey: ['id'])
  .eq('group_id', groupId)
  .listen((data) {
    // Update category list in Riverpod state
    // Notify expense entry screens to refresh category dropdown
  });
```

**Update Scenarios**:
- Admin renames category → All members see new name immediately
- Admin creates category → Appears in all members' category dropdowns
- Admin deletes category → Removed from all members' views

---

## Security Considerations

### Row Level Security (RLS)

**Read Access**:
- All group members can read categories (needed for expense entry)

**Write Access**:
- Only group admins can create/update/delete
- Default categories (is_default=true) cannot be deleted (enforced by RLS policy)

**Privacy**:
- Categories are group-scoped, no cross-group visibility
- Category names are visible to all group members (not sensitive data)

---

## Testing Strategy

### Unit Tests
- Validate category name trimming and length checks
- Test case-insensitive duplicate detection
- Test default category protection

### Integration Tests
- Create category as admin - success
- Create category as non-admin - permission denied
- Create duplicate category - conflict error
- Update category name - all expenses reflect change
- Delete category with expenses - reassignment works
- Delete default category - forbidden error
- Seed defaults on group creation - all 6 categories created

### Edge Cases
- Category with hundreds of expenses - deletion completes in < 1s
- Concurrent category renames - last write wins
- Delete category while another user adding expense with that category - graceful handling

---

## Migration Considerations

**Initial Deployment**:
1. Seed default categories for all existing groups
2. Migrate existing expense.category (string) to expense.category_id (FK):
   - Map known strings to default categories
   - Unknown strings create custom categories or map to "Other"
3. Drop old expense.category column after migration verified

**Rollback Plan**:
- Restore old category column from backup
- Remove expense_categories table
- Revert RLS policies

---

## Future Enhancements (Out of Scope)

- Category icons/colors
- Category budgets (budget per category)
- Nested categories (subcategories)
- Category templates (share across groups)
- Category usage analytics
