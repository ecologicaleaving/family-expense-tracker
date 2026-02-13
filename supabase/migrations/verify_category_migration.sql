-- Verification Script: Check Category Migration State
-- Run this BEFORE applying migration 20260213_drop_legacy_category_column.sql
-- to verify it's safe to drop the legacy category column

-- Check 1: Count expenses with NULL category_id (should be 0)
SELECT
  'Expenses with NULL category_id' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 0 THEN '✓ PASS - Safe to drop legacy column'
    ELSE '✗ FAIL - Run migration 022 first'
  END AS status
FROM public.expenses
WHERE category_id IS NULL;

-- Check 2: Verify the old category column exists
SELECT
  'Legacy category column exists' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) > 0 THEN '✓ Column exists - needs to be dropped'
    ELSE '✗ Column already dropped - migration not needed'
  END AS status
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'expenses'
  AND column_name = 'category';

-- Check 3: Verify expense_category ENUM type exists
SELECT
  'expense_category ENUM type exists' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) > 0 THEN '✓ Type exists - needs to be dropped'
    ELSE '✗ Type already dropped - migration not needed'
  END AS status
FROM pg_type
WHERE typname = 'expense_category';

-- Check 4: Verify all expenses have valid category_id references
SELECT
  'Expenses with invalid category_id' AS check_name,
  COUNT(*) AS count,
  CASE
    WHEN COUNT(*) = 0 THEN '✓ PASS - All category_id values are valid'
    ELSE '✗ FAIL - Some expenses reference non-existent categories'
  END AS status
FROM public.expenses e
LEFT JOIN public.expense_categories ec ON e.category_id = ec.id
WHERE e.category_id IS NOT NULL
  AND ec.id IS NULL;

-- Summary
SELECT '═══════════════════════════════════════' AS separator;
SELECT 'MIGRATION SAFETY SUMMARY' AS title;
SELECT '═══════════════════════════════════════' AS separator;

-- Final recommendation
DO $$
DECLARE
  null_category_count INTEGER;
  invalid_category_count INTEGER;
  legacy_column_exists BOOLEAN;
BEGIN
  -- Check for NULL category_id
  SELECT COUNT(*) INTO null_category_count
  FROM public.expenses WHERE category_id IS NULL;

  -- Check for invalid category_id references
  SELECT COUNT(*) INTO invalid_category_count
  FROM public.expenses e
  LEFT JOIN public.expense_categories ec ON e.category_id = ec.id
  WHERE e.category_id IS NOT NULL AND ec.id IS NULL;

  -- Check if legacy column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'expenses'
      AND column_name = 'category'
  ) INTO legacy_column_exists;

  -- Final verdict
  IF NOT legacy_column_exists THEN
    RAISE NOTICE '✓ Migration already applied - legacy column does not exist.';
  ELSIF null_category_count = 0 AND invalid_category_count = 0 THEN
    RAISE NOTICE '✓ SAFE TO PROCEED - All checks passed. You can apply migration 20260213_drop_legacy_category_column.sql';
  ELSE
    RAISE WARNING '✗ NOT SAFE - Found % expenses with NULL category_id and % with invalid category_id. Fix data first.',
      null_category_count, invalid_category_count;
  END IF;
END $$;
