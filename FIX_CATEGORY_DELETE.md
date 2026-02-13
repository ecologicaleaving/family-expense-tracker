# Fix for Category Deletion Error

## Problem
Category deletion fails with error: `"operator does not exist: expense_category = text"`

## Root Cause
The Supabase RLS DELETE policy for `expense_categories` table references the column `is_system_category`, but this column does not exist in the production database. Migration `053_add_system_category_flag.sql` was in the codebase but apparently not applied to production.

## Solution
Apply the fix migration that adds the missing column and ensures the RLS policy is correct.

## Steps to Fix

### Option A: Apply via Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com
   - Navigate to your project
   - Go to SQL Editor

2. **Run the Migration**
   - Copy the contents of: `supabase/migrations/20260213_fix_missing_is_system_category.sql`
   - Paste into SQL Editor
   - Click "Run"

3. **Verify the Fix**
   - In SQL Editor, run:
     ```sql
     SELECT column_name, data_type
     FROM information_schema.columns
     WHERE table_name = 'expense_categories'
     AND column_name = 'is_system_category';
     ```
   - Should return one row showing the column exists

4. **Test in App**
   - Try to delete a custom category
   - Should work without errors

### Option B: Apply via Supabase CLI

1. **Login to Supabase**
   ```bash
   supabase login
   ```

2. **Link to Your Project**
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **Push Migration**
   ```bash
   supabase db push
   ```

4. **Test in App**
   - Try to delete a custom category
   - Should work without errors

## What This Migration Does

1. **Adds the missing column**: `is_system_category BOOLEAN DEFAULT false`
2. **Marks "Varie" category as system**: Prevents deletion of the catch-all category
3. **Creates index**: For efficient querying of system categories
4. **Fixes the RLS policy**: Ensures the DELETE policy uses the correct column

## Verification Queries

After applying the migration, verify with these queries:

```sql
-- Check column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'expense_categories'
AND column_name = 'is_system_category';

-- Check RLS policy exists
SELECT policyname, tablename, cmd
FROM pg_policies
WHERE tablename = 'expense_categories'
AND cmd = 'DELETE';

-- Check "Varie" is marked as system
SELECT id, name, is_default, is_system_category
FROM expense_categories
WHERE name = 'Varie';
```

## Expected Results

After fix:
- Column `is_system_category` exists on `expense_categories` table
- DELETE policy `"Group admins can delete non-system categories"` exists
- Category deletion works for non-default, non-system categories
- System categories (like "Varie") cannot be deleted

## Files Changed
- Created: `supabase/migrations/20260213_fix_missing_is_system_category.sql`

## Related Files
- Original migration: `supabase/migrations/053_add_system_category_flag.sql`
- DELETE implementation: `lib/features/categories/data/datasources/category_remote_datasource.dart` (line 305)
- Repository validation: `lib/features/categories/data/repositories/category_repository_impl.dart` (line 230)
