-- Migration: Remove NOT NULL constraint from legacy category column
-- Date: 2026-01-04
--
-- Issue: Apps are using category_id (UUID) but the old category (TEXT) column
-- still has NOT NULL constraint, blocking inserts
--
-- Solution: Make category nullable to allow transition period where both
-- category and category_id can coexist

-- Remove NOT NULL constraint from category column
ALTER TABLE public.expenses
ALTER COLUMN category DROP NOT NULL;

-- Add comment explaining the change
COMMENT ON COLUMN public.expenses.category IS
  'Legacy category field (TEXT). Made nullable 2026-01-04 to allow transition to category_id (UUID). Will be dropped in future migration once all data is migrated.';

-- Verification: Show current state
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'expenses'
  AND column_name IN ('category', 'category_id');
