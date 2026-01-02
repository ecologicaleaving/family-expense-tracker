# Budget API Contract

**Feature**: Budget Management and Category Customization
**Version**: 1.0.0
**Date**: 2025-12-31

## Overview

This document defines the API contract for budget management operations in the family expense tracker. The API follows Supabase's client SDK patterns using direct database operations with Row Level Security (RLS) enforcement.

**Implementation Note**: Since this is a Supabase-based Flutter app, "API endpoints" are implemented as Dart repository methods that call Supabase client SDK functions. The contracts below describe the logical operations and their request/response shapes.

## Base Configuration

**Backend**: Supabase PostgreSQL
**Authentication**: Supabase Auth (JWT)
**Authorization**: Row Level Security (RLS) policies
**Error Handling**: Supabase exceptions mapped to app-specific failures

## Operations

### 1. Set/Update Group Budget

**Operation**: `setGroupBudget`
**Description**: Create or update the monthly budget for a family group (admin only)
**Authorization**: Must be group administrator

**Request**:
```dart
class SetGroupBudgetRequest {
  final String groupId;      // UUID of family group
  final int amount;          // Budget amount in whole euros (>= 0)
  final int month;           // Month number (1-12)
  final int year;            // Year (>= 2000)
}
```

**Response**:
```dart
class GroupBudgetResponse {
  final String id;           // UUID of budget
  final String groupId;
  final int amount;
  final int month;
  final int year;
  final String createdBy;    // UUID of admin who set it
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Database Operation**:
```sql
INSERT INTO group_budgets (group_id, amount, month, year, created_by)
VALUES ($1, $2, $3, $4, auth.uid())
ON CONFLICT (group_id, year, month)
DO UPDATE SET
  amount = EXCLUDED.amount,
  updated_at = now(),
  created_by = auth.uid()
RETURNING *;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group administrator
- `ValidationFailure`: Invalid amount (<0) or invalid month/year
- `NotFoundFailure`: Group does not exist

**Validation Rules**:
- amount >= 0
- month between 1 and 12
- year >= 2000 and <= current_year + 5

---

### 2. Get Group Budget

**Operation**: `getGroupBudget`
**Description**: Retrieve the budget for a specific group and month
**Authorization**: Must be group member

**Request**:
```dart
class GetGroupBudgetRequest {
  final String groupId;
  final int month;
  final int year;
}
```

**Response**:
```dart
class GroupBudgetResponse {
  // Same as setGroupBudget response
}
```

**Nullable Response**: Returns `null` if no budget set for that month/year

**Database Operation**:
```sql
SELECT * FROM group_budgets
WHERE group_id = $1 AND year = $2 AND month = $3
LIMIT 1;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group member
- `NotFoundFailure`: Group does not exist

---

### 3. Get Group Budget Statistics

**Operation**: `getGroupBudgetStats`
**Description**: Get budget consumption statistics (amount spent, remaining, percentage) for a specific month
**Authorization**: Must be group member

**Request**:
```dart
class GetGroupBudgetStatsRequest {
  final String groupId;
  final int month;
  final int year;
  final String? userTimezone; // Optional: user's IANA timezone (e.g., "Europe/Rome")
}
```

**Response**:
```dart
class BudgetStatsResponse {
  final String? budgetId;           // null if no budget set
  final int? budgetAmount;          // null if no budget set
  final int spentAmount;            // Sum of expenses (rounded up to euros)
  final int? remainingAmount;       // null if no budget set
  final double? percentageUsed;     // null if no budget set (0-100+)
  final bool isOverBudget;          // true if spent > budget
  final bool isNearLimit;           // true if spent >= 80% of budget
  final int expenseCount;           // Number of expenses in period
}
```

**Database Operation**:
```sql
-- Supabase function or application-level aggregation
SELECT
  gb.id as budget_id,
  gb.amount as budget_amount,
  COALESCE(SUM(CEIL(e.amount)), 0) as spent_amount,
  gb.amount - COALESCE(SUM(CEIL(e.amount)), 0) as remaining_amount,
  CASE
    WHEN gb.amount > 0 THEN
      ROUND((COALESCE(SUM(CEIL(e.amount)), 0)::NUMERIC / gb.amount::NUMERIC) * 100, 2)
    ELSE 0
  END as percentage_used,
  COUNT(e.id) as expense_count
FROM group_budgets gb
LEFT JOIN expenses e ON
  e.group_id = gb.group_id
  AND e.is_group_expense = true
  AND EXTRACT(YEAR FROM e.date AT TIME ZONE COALESCE($4, 'UTC')) = gb.year
  AND EXTRACT(MONTH FROM e.date AT TIME ZONE COALESCE($4, 'UTC')) = gb.month
WHERE gb.group_id = $1 AND gb.year = $2 AND gb.month = $3
GROUP BY gb.id, gb.amount;
```

**Errors**:
- `PermissionDeniedFailure`: User is not group member

**Notes**:
- If no budget is set, returns stats with null budget fields but actual spent amount
- Expense amounts rounded up to next whole euro per FR-026
- Timezone parameter used for determining which expenses belong to the month

---

### 4. Get Group Budget History

**Operation**: `getGroupBudgetHistory`
**Description**: Retrieve all historical budgets for a group
**Authorization**: Must be group member

**Request**:
```dart
class GetGroupBudgetHistoryRequest {
  final String groupId;
  final int? limit;           // Optional: max number of months to return
  final int? startYear;       // Optional: filter from this year
}
```

**Response**:
```dart
class BudgetHistoryResponse {
  final List<GroupBudgetWithStats> budgets;
}

class GroupBudgetWithStats {
  final GroupBudgetResponse budget;
  final BudgetStatsResponse stats;
}
```

**Database Operation**:
```sql
SELECT * FROM group_budgets
WHERE group_id = $1
  AND ($2::INT IS NULL OR year >= $2)
ORDER BY year DESC, month DESC
LIMIT COALESCE($3, 12);
```

**Errors**:
- `PermissionDeniedFailure`: User is not group member

---

### 5. Set/Update Personal Budget

**Operation**: `setPersonalBudget`
**Description**: Create or update the monthly budget for the current user
**Authorization**: User can only manage their own budget

**Request**:
```dart
class SetPersonalBudgetRequest {
  final int amount;          // Budget amount in whole euros (>= 0)
  final int month;           // Month number (1-12)
  final int year;            // Year (>= 2000)
}
```

**Response**:
```dart
class PersonalBudgetResponse {
  final String id;
  final String userId;
  final int amount;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**Database Operation**:
```sql
INSERT INTO personal_budgets (user_id, amount, month, year)
VALUES (auth.uid(), $1, $2, $3)
ON CONFLICT (user_id, year, month)
DO UPDATE SET
  amount = EXCLUDED.amount,
  updated_at = now()
RETURNING *;
```

**Errors**:
- `ValidationFailure`: Invalid amount or date

**Validation Rules**:
- Same as group budget validation

---

### 6. Get Personal Budget

**Operation**: `getPersonalBudget`
**Description**: Retrieve the budget for the current user for a specific month
**Authorization**: User can only access their own budget

**Request**:
```dart
class GetPersonalBudgetRequest {
  final int month;
  final int year;
}
```

**Response**:
```dart
class PersonalBudgetResponse {
  // Same as setPersonalBudget response
}
```

**Nullable Response**: Returns `null` if no budget set for that month/year

**Database Operation**:
```sql
SELECT * FROM personal_budgets
WHERE user_id = auth.uid() AND year = $1 AND month = $2
LIMIT 1;
```

---

### 7. Get Personal Budget Statistics

**Operation**: `getPersonalBudgetStats`
**Description**: Get budget consumption statistics for the current user (includes both personal expenses and user's share of group expenses)
**Authorization**: User can only access their own stats

**Request**:
```dart
class GetPersonalBudgetStatsRequest {
  final int month;
  final int year;
  final String? userTimezone;
}
```

**Response**:
```dart
class BudgetStatsResponse {
  // Same structure as group budget stats
}
```

**Database Operation**:
```sql
SELECT
  pb.id as budget_id,
  pb.amount as budget_amount,
  COALESCE(SUM(CEIL(e.amount)), 0) as spent_amount,
  pb.amount - COALESCE(SUM(CEIL(e.amount)), 0) as remaining_amount,
  CASE
    WHEN pb.amount > 0 THEN
      ROUND((COALESCE(SUM(CEIL(e.amount)), 0)::NUMERIC / pb.amount::NUMERIC) * 100, 2)
    ELSE 0
  END as percentage_used,
  COUNT(e.id) as expense_count
FROM personal_budgets pb
LEFT JOIN expenses e ON
  e.created_by = pb.user_id
  AND EXTRACT(YEAR FROM e.date AT TIME ZONE COALESCE($3, 'UTC')) = pb.year
  AND EXTRACT(MONTH FROM e.date AT TIME ZONE COALESCE($3, 'UTC')) = pb.month
WHERE pb.user_id = auth.uid() AND pb.year = $1 AND pb.month = $2
GROUP BY pb.id, pb.amount;
```

**Notes**:
- Includes ALL expenses created by user (both personal and group expenses)
- This ensures user's personal budget tracks their total spending contribution

---

### 8. Get Personal Budget History

**Operation**: `getPersonalBudgetHistory`
**Description**: Retrieve all historical budgets for the current user
**Authorization**: User can only access their own history

**Request**:
```dart
class GetPersonalBudgetHistoryRequest {
  final int? limit;
  final int? startYear;
}
```

**Response**:
```dart
class BudgetHistoryResponse {
  final List<PersonalBudgetWithStats> budgets;
}

class PersonalBudgetWithStats {
  final PersonalBudgetResponse budget;
  final BudgetStatsResponse stats;
}
```

**Database Operation**:
```sql
SELECT * FROM personal_budgets
WHERE user_id = auth.uid()
  AND ($1::INT IS NULL OR year >= $1)
ORDER BY year DESC, month DESC
LIMIT COALESCE($2, 12);
```

---

## Error Handling

### Error Types

All operations return `Result<T, Failure>` using the Dartz functional programming pattern already in the codebase.

**Failure Types**:
```dart
abstract class Failure {
  final String message;
}

class ServerFailure extends Failure {
  // Supabase errors, network errors
}

class PermissionDeniedFailure extends Failure {
  // RLS policy violations, not group admin/member
}

class ValidationFailure extends Failure {
  // Invalid input data
}

class NotFoundFailure extends Failure {
  // Resource doesn't exist
}
```

### HTTP-like Status Mapping

While Supabase doesn't use HTTP codes, conceptual mapping:
- Success: 200/201 equivalent
- Validation errors: 400 equivalent
- Permission denied: 403 equivalent
- Not found: 404 equivalent
- Server errors: 500 equivalent

## Performance Requirements

- Budget read operations: < 200ms p95
- Budget write operations: < 500ms p95
- Budget stats calculation: < 500ms p95 (per spec SC-003: updates within 2s total includes network + calculation)
- History queries: < 1s p95 for 12 months of data

## Caching Strategy

**Client-Side (Drift)**:
- Cache current month budget stats for offline viewing
- Cache personal budget settings
- Cache last 3 months of budget history

**Invalidation**:
- Invalidate on budget update
- Invalidate on expense create/update/delete
- Background sync every 5 minutes when online

**Optimistic Updates**:
- Budget updates reflected immediately in UI
- Background sync confirms with server
- Rollback on conflict/error

## Real-time Updates

**Supabase Realtime Subscriptions**:
- Subscribe to `group_budgets` table for group budget changes
- Subscribe to `expenses` table for expense changes affecting budget
- Update UI within 2s of change (per SC-003, SC-005)

**Implementation** (pending Phase 0 research):
```dart
// Pseudocode - actual implementation after research
supabase
  .from('expenses')
  .stream(primaryKey: ['id'])
  .eq('group_id', groupId)
  .listen((data) {
    // Recalculate budget stats
    // Update Riverpod state
  });
```

## Security Considerations

### Authentication
- All operations require valid Supabase JWT token
- Token includes user ID for RLS policy enforcement

### Authorization
- RLS policies enforce group membership and admin privileges
- Personal budgets accessible only to owner
- Group budgets require group membership

### Data Validation
- All inputs validated before database operations
- SQL injection prevented by parameterized queries
- Amount bounds checking (0 <= amount <= 1000000)

### Privacy
- Personal budget data not exposed to other users
- Budget stats respect expense privacy (personal expenses excluded from group stats)

## Testing Strategy

### Unit Tests
- Test budget calculation logic with various scenarios
- Test timezone handling in date filtering
- Test rounding logic for euro conversion

### Integration Tests
- Test budget CRUD operations end-to-end
- Test RLS policies prevent unauthorized access
- Test real-time updates trigger correctly
- Test optimistic updates and rollback

### Test Cases
1. Set group budget as admin - success
2. Set group budget as non-admin - permission denied
3. Get budget stats with no expenses - returns 0 spent
4. Get budget stats with expenses - correct aggregation
5. Get budget stats over budget - isOverBudget true
6. Personal budget includes both personal and group expenses
7. Budget history sorted by date descending
8. Concurrent budget updates handled correctly

## Migration Considerations

**Backward Compatibility**:
- Old app versions without budget feature can still use expense tracking
- Budget columns have defaults to prevent null issues
- Graceful degradation if budget feature unavailable

**Forward Compatibility**:
- Budget schema designed to support future enhancements (weekly/annual budgets)
- Category reference nullable to support migration period
