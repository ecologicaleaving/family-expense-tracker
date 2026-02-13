# Category Delete Error Fix

## Problem Summary

**Error**: `operator does not exist: expense_category = text`

**When it occurs**: When attempting to DELETE a category from the `expense_categories` table

**Root cause**: The `expenses` table still contains the legacy `category` column (PostgreSQL ENUM type `expense_category`) from the original schema. This column was migrated to `category_id` (UUID) in migration 022, but the old column was never dropped. When RLS policies execute during DELETE operations, PostgreSQL encounters type mismatches between the ENUM and text comparisons.

## Technical Details

### Original Schema (Migration 001)
```sql
CREATE TYPE expense_category AS ENUM (
    'food', 'utilities', 'transport', 'healthcare',
    'entertainment', 'household', 'other'
);

CREATE TABLE public.expenses (
    ...
    category expense_category NOT NULL,
    ...
);
```

### Migration to UUID (Migration 013 & 022)
- Migration 013: Added `category_id UUID` column
- Migration 022: Migrated all data from `category` to `category_id`
- **ISSUE**: Line 45 of migration 022 is commented out, so the old column was never dropped:
  ```sql
  -- ALTER TABLE public.expenses DROP COLUMN IF EXISTS category;
  ```

### Impact
- The DELETE RLS policy on `expense_categories` fails when checking related expenses
- PostgreSQL cannot compare the ENUM type with text values in policy logic
- Category deletion is completely broken

## Solution

Drop the legacy `category` column and the `expense_category` ENUM type.

## Pre-Migration Verification

**Step 1**: Run the verification script to ensure it's safe to proceed:

```bash
# Connect to your Supabase database via psql or SQL Editor
psql <your-connection-string> -f supabase/migrations/verify_category_migration.sql
```

Or in Supabase Dashboard SQL Editor:
```sql
-- Paste contents of verify_category_migration.sql
```

**Expected output**:
```
✓ PASS - Safe to drop legacy column
✓ Column exists - needs to be dropped
✓ Type exists - needs to be dropped
✓ PASS - All category_id values are valid
✓ SAFE TO PROCEED - All checks passed
```

## Applying the Fix

### Option A: Via Supabase CLI

```bash
# Run the migration
supabase db push

# Or apply specific migration
supabase migration up --version 20260213_drop_legacy_category_column
```

### Option B: Via Supabase Dashboard

1. Go to **SQL Editor** in Supabase Dashboard
2. Open `supabase/migrations/20260213_drop_legacy_category_column.sql`
3. Copy and paste the contents
4. Click **Run**

### Option C: Manual SQL Execution

Connect to your database and run:

```sql
-- Verify safety first
SELECT COUNT(*) FROM public.expenses WHERE category_id IS NULL;
-- Should return 0

-- Drop the legacy column
ALTER TABLE public.expenses DROP COLUMN IF EXISTS category;

-- Drop the ENUM type
DROP TYPE IF EXISTS expense_category CASCADE;

-- Drop old index
DROP INDEX IF EXISTS public.idx_expenses_category;
```

## Post-Migration Verification

**Step 1**: Verify the column is gone:
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'expenses'
  AND column_name IN ('category', 'category_id');
```

**Expected result**: Only `category_id` should appear (type: uuid)

**Step 2**: Verify the ENUM type is gone:
```sql
SELECT typname FROM pg_type WHERE typname = 'expense_category';
```

**Expected result**: 0 rows

**Step 3**: Test category deletion in the app:
1. Open the app as an admin user
2. Go to category management
3. Try to delete a non-default, non-system category
4. Should succeed without errors

## Files Created

1. **Migration**: `supabase/migrations/20260213_drop_legacy_category_column.sql`
   - Drops the legacy `category` column
   - Drops the `expense_category` ENUM type
   - Includes safety checks

2. **Verification Script**: `supabase/migrations/verify_category_migration.sql`
   - Pre-migration safety checks
   - Data integrity validation
   - Clear pass/fail indicators

3. **This Documentation**: `CATEGORY_DELETE_FIX.md`

## Rollback (If Needed)

If you need to rollback this migration (not recommended):

```sql
-- Recreate the ENUM type
CREATE TYPE expense_category AS ENUM (
    'food', 'utilities', 'transport', 'healthcare',
    'entertainment', 'household', 'other'
);

-- Add the column back
ALTER TABLE public.expenses
  ADD COLUMN category expense_category;

-- Repopulate from category_id (reverse migration)
UPDATE public.expenses e
SET category = (
  SELECT LOWER(ec.name)::expense_category
  FROM public.expense_categories ec
  WHERE ec.id = e.category_id
  LIMIT 1
)
WHERE category IS NULL;
```

**WARNING**: Rollback is NOT recommended because:
- The old column is not used by any application code
- Keeping it creates technical debt
- You'll continue to experience the DELETE error

## Why This Fix Works

1. **Removes the source of type confusion**: No more ENUM vs text comparisons
2. **Aligns with app code**: The Flutter app only uses `category_id`
3. **Completes migration 022**: Finishes what was started but not completed
4. **No RLS policy changes needed**: Policies work correctly with only `category_id`
5. **Clean database schema**: Single source of truth for category references

## Testing Checklist

After applying the migration, test these scenarios:

- [ ] View categories (should load normally)
- [ ] Create a new category (should work)
- [ ] Edit a category name (should work)
- [ ] Change category icon (should work)
- [ ] Toggle category active status (should work)
- [ ] **Delete a custom category** (THIS WAS BROKEN, should now work)
- [ ] Try to delete a default category (should be blocked by RLS)
- [ ] Try to delete a system category (should be blocked by RLS)
- [ ] Create expense with a category (should work)
- [ ] View expenses by category (should work)

## Support

If you encounter issues after applying this migration:

1. Check the verification queries in the "Post-Migration Verification" section
2. Review Supabase logs for detailed error messages
3. Verify your RLS policies are correctly defined
4. Check that `is_system_category` and `is_active` columns exist on `expense_categories`

## Migration Timeline

- **2026-01-01**: Migration 001 - Created `expense_category` ENUM and `category` column
- **2026-01-03**: Migration 022 - Migrated data to `category_id`, but didn't drop old column
- **2026-02-13**: Migration 20260213 - **Drops legacy column and ENUM type** (this fix)
