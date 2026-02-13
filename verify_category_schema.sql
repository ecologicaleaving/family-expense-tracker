-- Verification Script for Category Delete Bug Fix
-- Run this in Supabase SQL Editor to diagnose the issue

-- ============================================
-- 1. Check if is_system_category column exists
-- ============================================
SELECT 'Column Check' AS test_name,
       CASE
           WHEN COUNT(*) > 0 THEN 'PASS - Column exists'
           ELSE 'FAIL - Column missing (THIS IS THE BUG!)'
       END AS result
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'expense_categories'
  AND column_name = 'is_system_category';

-- ============================================
-- 2. List all columns in expense_categories
-- ============================================
SELECT 'All Columns' AS test_name,
       column_name,
       data_type,
       column_default,
       is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'expense_categories'
ORDER BY ordinal_position;

-- ============================================
-- 3. Check DELETE RLS policies
-- ============================================
SELECT 'DELETE Policy Check' AS test_name,
       schemaname,
       tablename,
       policyname,
       permissive,
       roles,
       cmd,
       qual AS using_expression
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'expense_categories'
  AND cmd = 'DELETE';

-- ============================================
-- 4. Check if index exists
-- ============================================
SELECT 'Index Check' AS test_name,
       indexname,
       indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = 'expense_categories'
  AND indexname = 'idx_expense_categories_system';

-- ============================================
-- 5. Sample categories with all flags
-- ============================================
SELECT 'Sample Categories' AS test_name,
       id,
       name,
       is_default,
       CASE
           WHEN EXISTS (
               SELECT 1
               FROM information_schema.columns
               WHERE table_name = 'expense_categories'
               AND column_name = 'is_system_category'
           ) THEN 'Column exists - check individual rows'
           ELSE 'Column does not exist'
       END AS system_category_status,
       is_active,
       group_id
FROM public.expense_categories
LIMIT 5;
