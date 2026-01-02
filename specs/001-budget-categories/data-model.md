# Data Model: Budget Management and Category Customization

**Feature**: Budget Management and Category Customization
**Branch**: `001-budget-categories`
**Date**: 2025-12-31

## Overview

This document defines the data entities, relationships, and database schema for the budget management and category customization feature. The model extends the existing expense tracker database with three new tables and modifies the expenses table to support group/personal classification.

## Entity Definitions

### 1. GroupBudget

Monthly budget for a family group set by an administrator.

**Attributes:**
- `id` (UUID, PK): Unique identifier
- `group_id` (UUID, FK → family_groups.id): Reference to family group
- `amount` (INTEGER, NOT NULL): Budget amount in whole euros (no cents)
- `month` (INTEGER, NOT NULL): Month number (1-12)
- `year` (INTEGER, NOT NULL): Year (e.g., 2025)
- `created_by` (UUID, FK → profiles.id): User who set the budget (must be admin)
- `created_at` (TIMESTAMP, NOT NULL): Creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL): Last update timestamp

**Constraints:**
- `amount` must be >= 0
- `month` must be between 1 and 12
- `year` must be >= 2000
- UNIQUE constraint on (group_id, year, month) - one budget per group per month
- Foreign key `created_by` must reference a user who is admin of the group

**Indexes:**
- Primary key on `id`
- Index on (group_id, year, month) for fast lookups
- Index on `created_by`

### 2. PersonalBudget

Monthly budget for an individual user's personal expenses.

**Attributes:**
- `id` (UUID, PK): Unique identifier
- `user_id` (UUID, FK → profiles.id): Reference to user
- `amount` (INTEGER, NOT NULL): Budget amount in whole euros (no cents)
- `month` (INTEGER, NOT NULL): Month number (1-12)
- `year` (INTEGER, NOT NULL): Year (e.g., 2025)
- `created_at` (TIMESTAMP, NOT NULL): Creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL): Last update timestamp

**Constraints:**
- `amount` must be >= 0
- `month` must be between 1 and 12
- `year` must be >= 2000
- UNIQUE constraint on (user_id, year, month) - one budget per user per month

**Indexes:**
- Primary key on `id`
- Index on (user_id, year, month) for fast lookups

### 3. ExpenseCategory

Customizable expense categories managed by group administrators.

**Attributes:**
- `id` (UUID, PK): Unique identifier
- `name` (VARCHAR(50), NOT NULL): Category name (e.g., "Food", "Pet care")
- `group_id` (UUID, FK → family_groups.id): Reference to family group
- `is_default` (BOOLEAN, NOT NULL, DEFAULT false): True for system default categories
- `created_by` (UUID, FK → profiles.id, NULLABLE): User who created category (null for defaults)
- `created_at` (TIMESTAMP, NOT NULL): Creation timestamp
- `updated_at` (TIMESTAMP, NOT NULL): Last update timestamp

**Constraints:**
- `name` length must be between 1 and 50 characters
- UNIQUE constraint on (group_id, name) - no duplicate names within group
- Default categories (is_default=true) cannot be deleted
- Only group administrators can create/update/delete categories

**Indexes:**
- Primary key on `id`
- Index on `group_id` for listing all group categories
- Index on (group_id, name) for name uniqueness checks

**Default Categories** (seeded per group on group creation):
- Food
- Utilities
- Transport
- Healthcare
- Entertainment
- Other

### 4. Expense (Modified)

Existing expense table modified to add group/personal classification.

**New Attributes:**
- `is_group_expense` (BOOLEAN, NOT NULL, DEFAULT true): True for group expenses, false for personal
- `category_id` (UUID, FK → expense_categories.id, NULLABLE): Reference to category (replaces old string category field)

**Modified Attributes:**
- `category` (VARCHAR, DEPRECATED): Old category field to be removed after migration

**Migration Notes:**
- All existing expenses default to `is_group_expense = true`
- Category migration: map old string categories to new category IDs, unmapped go to "Other"
- Old `category` column can be dropped after successful migration verification

**Privacy Rules (RLS):**
- Group expenses (is_group_expense=true): visible to all group members
- Personal expenses (is_group_expense=false): visible ONLY to creator (created_by)
- Group administrators CANNOT view other members' personal expenses

## Entity Relationships

```
User (profiles)
  ├─ 1:N → PersonalBudget (user has many budgets, one per month)
  ├─ 1:N → GroupBudget (user creates many group budgets as admin)
  ├─ 1:N → ExpenseCategory (user creates many categories as admin)
  └─ 1:N → Expense (user creates many expenses)

FamilyGroup (family_groups)
  ├─ 1:N → GroupBudget (group has many budgets, one per month)
  ├─ 1:N → ExpenseCategory (group has many categories)
  └─ 1:N → Expense (group has many expenses)

GroupBudget
  ├─ N:1 → FamilyGroup (many budgets belong to one group)
  └─ N:1 → User (created_by)

PersonalBudget
  └─ N:1 → User (many budgets belong to one user)

ExpenseCategory
  ├─ N:1 → FamilyGroup (many categories belong to one group)
  ├─ N:1 → User (created_by, nullable for defaults)
  └─ 1:N → Expense (one category has many expenses)

Expense
  ├─ N:1 → User (created_by)
  ├─ N:1 → FamilyGroup (group_id)
  └─ N:1 → ExpenseCategory (category_id)
```

## Database Schema (PostgreSQL/Supabase)

### group_budgets Table

```sql
CREATE TABLE group_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  UNIQUE(group_id, year, month)
);

CREATE INDEX idx_group_budgets_lookup ON group_budgets(group_id, year, month);
CREATE INDEX idx_group_budgets_created_by ON group_budgets(created_by);

-- RLS Policies
ALTER TABLE group_budgets ENABLE ROW LEVEL SECURITY;

-- Group members can view their group's budgets
CREATE POLICY "Users can view their group budgets"
  ON group_budgets FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Only group admins can create/update group budgets
CREATE POLICY "Group admins can manage group budgets"
  ON group_budgets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = group_budgets.group_id
        AND is_group_admin = true
    )
  );
```

### personal_budgets Table

```sql
CREATE TABLE personal_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  UNIQUE(user_id, year, month)
);

CREATE INDEX idx_personal_budgets_lookup ON personal_budgets(user_id, year, month);

-- RLS Policies
ALTER TABLE personal_budgets ENABLE ROW LEVEL SECURITY;

-- Users can only manage their own personal budgets
CREATE POLICY "Users can manage their own personal budgets"
  ON personal_budgets FOR ALL
  USING (user_id = auth.uid());
```

### expense_categories Table

```sql
CREATE TABLE expense_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL,
  group_id UUID NOT NULL REFERENCES family_groups(id) ON DELETE CASCADE,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  UNIQUE(group_id, name)
);

CREATE INDEX idx_expense_categories_group ON expense_categories(group_id);
CREATE INDEX idx_expense_categories_name ON expense_categories(group_id, name);

-- RLS Policies
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;

-- Group members can view their group's categories
CREATE POLICY "Users can view their group categories"
  ON expense_categories FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Only group admins can create/update/delete categories
CREATE POLICY "Group admins can manage categories"
  ON expense_categories FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = expense_categories.group_id
        AND is_group_admin = true
    )
  );

CREATE POLICY "Group admins can update categories"
  ON expense_categories FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = expense_categories.group_id
        AND is_group_admin = true
    )
  );

CREATE POLICY "Group admins can delete non-default categories"
  ON expense_categories FOR DELETE
  USING (
    is_default = false
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid()
        AND group_id = expense_categories.group_id
        AND is_group_admin = true
    )
  );
```

### expenses Table (Migration)

```sql
-- Add new columns
ALTER TABLE expenses
  ADD COLUMN is_group_expense BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL;

-- Create index on new columns
CREATE INDEX idx_expenses_is_group ON expenses(is_group_expense);
CREATE INDEX idx_expenses_category ON expenses(category_id);

-- Update RLS policies for personal expense privacy
CREATE POLICY "Users can view group expenses in their group"
  ON expenses FOR SELECT
  USING (
    is_group_expense = true
    AND group_id IN (
      SELECT group_id FROM profiles WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can view their own personal expenses"
  ON expenses FOR SELECT
  USING (
    is_group_expense = false
    AND created_by = auth.uid()
  );

-- Note: Drop old RLS policies and 'category' column after migration complete
```

## Data Validation Rules

### Budget Amount Validation
- Must be whole euros (INTEGER, no decimals)
- Must be >= 0
- Recommended max: 1,000,000 EUR (application-level validation)

### Category Name Validation
- Length: 1-50 characters
- No leading/trailing whitespace
- Unique within group (case-insensitive recommended)
- Cannot be empty string

### Date Validation
- Month: 1-12
- Year: >= 2000, <= current_year + 5 (prevent far-future budgets)
- Budget queries use user's local timezone for "current month" determination

### Expense Classification Validation
- `is_group_expense` cannot be NULL
- When changing from personal to group: user must be in a group
- When changing from group to personal: verify user owns the expense

## State Transitions

### Budget Lifecycle
1. **Created**: Admin/user creates budget for a specific month/year
2. **Active**: Current month budget being tracked
3. **Historical**: Past month budget (read-only, preserved for reporting)
4. **Updated**: Admin/user modifies budget amount (preserves month/year)

Note: Budgets are never deleted, only updated or become historical.

### Category Lifecycle
1. **Created**: Admin creates custom category (or system seeds defaults on group creation)
2. **Active**: Category available for expense assignment
3. **Renamed**: Admin updates category name (all existing expenses automatically reflect new name)
4. **Deleted**: Admin removes category after reassigning/moving expenses

Note: Default categories (is_default=true) cannot transition to Deleted state.

### Expense Classification Lifecycle
1. **Created as Group**: New expense marked is_group_expense=true (default)
2. **Created as Personal**: User explicitly marks expense as personal
3. **Reclassified to Personal**: User changes existing group expense to personal
4. **Reclassified to Group**: User changes existing personal expense to group

Each reclassification triggers budget recalculation for affected user(s).

## Computed Fields / Views

### Budget Statistics (Not Stored)

Calculated on-demand:

```sql
-- Group Budget Stats for a specific month
SELECT
  gb.id as budget_id,
  gb.amount as budget_amount,
  COALESCE(SUM(CEIL(e.amount)), 0) as spent_amount, -- Round up to whole euros
  gb.amount - COALESCE(SUM(CEIL(e.amount)), 0) as remaining_amount,
  CASE
    WHEN gb.amount > 0 THEN
      ROUND((COALESCE(SUM(CEIL(e.amount)), 0)::NUMERIC / gb.amount::NUMERIC) * 100, 2)
    ELSE 0
  END as percentage_used
FROM group_budgets gb
LEFT JOIN expenses e ON
  e.group_id = gb.group_id
  AND e.is_group_expense = true
  AND EXTRACT(YEAR FROM e.date AT TIME ZONE 'UTC') = gb.year
  AND EXTRACT(MONTH FROM e.date AT TIME ZONE 'UTC') = gb.month
WHERE gb.group_id = $1 AND gb.year = $2 AND gb.month = $3
GROUP BY gb.id, gb.amount;

-- Personal Budget Stats (includes both personal expenses and user's group expenses)
SELECT
  pb.id as budget_id,
  pb.amount as budget_amount,
  COALESCE(SUM(CEIL(e.amount)), 0) as spent_amount,
  pb.amount - COALESCE(SUM(CEIL(e.amount)), 0) as remaining_amount,
  CASE
    WHEN pb.amount > 0 THEN
      ROUND((COALESCE(SUM(CEIL(e.amount)), 0)::NUMERIC / pb.amount::NUMERIC) * 100, 2)
    ELSE 0
  END as percentage_used
FROM personal_budgets pb
LEFT JOIN expenses e ON
  e.created_by = pb.user_id
  AND EXTRACT(YEAR FROM e.date AT TIME ZONE 'UTC') = pb.year
  AND EXTRACT(MONTH FROM e.date AT TIME ZONE 'UTC') = pb.month
WHERE pb.user_id = $1 AND pb.year = $2 AND pb.month = $3
GROUP BY pb.id, pb.amount;
```

Note: Timezone handling for "current month" determination will be refined based on Phase 0 research results.

## Migration Strategy

### Phase 1: Add New Tables
1. Create `group_budgets` table with indexes and RLS
2. Create `personal_budgets` table with indexes and RLS
3. Create `expense_categories` table with indexes and RLS
4. Seed default categories for all existing groups

### Phase 2: Modify Expenses Table
1. Add `is_group_expense` column with DEFAULT true (backfills existing rows)
2. Add `category_id` column (nullable initially)
3. Migrate old string `category` values to `category_id` foreign keys
4. Add indexes on new columns
5. Update RLS policies for personal expense privacy

### Phase 3: Cleanup
1. Verify all expenses have valid `category_id` or are assigned to "Other"
2. Drop old `category` column
3. Make `category_id` NOT NULL if required

### Rollback Plan
- Each migration phase is a separate SQL file
- Can rollback by running reverse migrations in order
- Data preserved in old columns until Phase 3 cleanup

## Performance Considerations

### Query Optimization
- Budget stats queries use indexes on (group_id, year, month) and (user_id, year, month)
- Expense aggregation filtered by date uses index on expense.date
- Category lookups use composite index on (group_id, name)

### Caching Strategy
- Client-side (Drift): Cache current month budget stats for offline viewing
- Invalidate cache when new expense added or budget updated
- Background sync with Supabase for multi-device consistency

### Scalability Estimates
- 10 users per group × 100 groups = 1,000 personal budgets per month
- 100 groups × 1 group budget per month = 100 group budgets per month
- ~12,000 budgets per year total
- Expense queries limited to single month (max ~500 expenses per group per month)
- All queries should complete in <500ms with proper indexes

## Security & Privacy

### Row Level Security (RLS)
- All tables have RLS enabled
- Group budgets visible to group members, editable only by admins
- Personal budgets visible/editable only by owner
- Categories visible to group members, editable only by admins
- Personal expenses (is_group_expense=false) visible ONLY to creator
- Group expenses visible to all group members

### Data Isolation
- No cross-group data leakage (enforced by RLS policies)
- Personal expenses cannot be queried by other users (including admins)
- Budget calculations respect user ownership and group membership

### Audit Trail
- All tables have `created_at` and `updated_at` timestamps
- `created_by` field tracks who created budgets/categories
- Expense modifications already tracked in existing expense audit system

## Open Questions (Pending Research)

1. ~~Timezone handling for budget resets~~ - Research in progress
2. ~~RLS policy performance with complex queries~~ - Research in progress
3. Should budget history be materialized or computed on-demand?
4. Default category seeding: per-group or global template?
5. Should we store monthly budget snapshots for faster historical queries?
