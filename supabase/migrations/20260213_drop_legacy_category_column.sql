-- Migration: Drop Legacy category Column and ENUM Type
-- Date: 2026-02-13
-- Purpose: Complete the migration started in 022 by removing the old category column
--
-- CONTEXT:
-- Migration 022 migrated all expense category data from the old 'category' column (ENUM type)
-- to the new 'category_id' column (UUID foreign key), but left the old column in place.
-- This legacy column causes "operator does not exist: expense_category = text" errors
-- when RLS policies try to process DELETE operations on expense_categories.
--
-- SAFETY:
-- The old column has been unused since migration 022 (2026-01-03).
-- All app code uses category_id exclusively.

-- Step 1: Verify that category_id has been populated for all expenses
-- This query should return 0 for safe migration
DO $$
DECLARE
  orphan_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO orphan_count
  FROM public.expenses
  WHERE category_id IS NULL;

  IF orphan_count > 0 THEN
    RAISE EXCEPTION 'Migration blocked: % expenses have NULL category_id. Run migration 022 first.', orphan_count;
  END IF;

  RAISE NOTICE 'Verification passed: All expenses have category_id populated.';
END $$;

-- Step 2: Drop the old category column from expenses table
ALTER TABLE public.expenses
  DROP COLUMN IF EXISTS category;

-- Step 3: Drop the expense_category ENUM type (no longer used)
DROP TYPE IF EXISTS expense_category CASCADE;

-- Step 4: Drop the old index if it still exists
DROP INDEX IF EXISTS public.idx_expenses_category;

-- Add comment for documentation
COMMENT ON TABLE public.expenses IS
  'Family expenses with category tracking via category_id (UUID foreign key). Legacy ENUM category column removed in migration 20260213.';

-- Log completion
DO $$
BEGIN
  RAISE NOTICE 'Migration completed: Legacy category column and expense_category ENUM type removed successfully.';
END $$;
