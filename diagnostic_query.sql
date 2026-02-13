-- ================================================
-- DIAGNOSTIC QUERY: Find all references to "category" column
-- ================================================

-- 1. Check all columns in expenses table
SELECT 'EXPENSES COLUMNS' as check_type, column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'expenses'
ORDER BY ordinal_position;

-- 2. Check all RLS policies on expense_categories
SELECT 'EXPENSE_CATEGORIES POLICIES' as check_type,
       policyname,
       cmd,
       qual as using_expression,
       with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'expense_categories';

-- 3. Check all triggers on expense_categories
SELECT 'EXPENSE_CATEGORIES TRIGGERS' as check_type,
       trigger_name,
       event_manipulation,
       action_statement
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table = 'expense_categories';

-- 4. Check all functions that reference "category" (not "category_id")
SELECT 'FUNCTIONS WITH CATEGORY' as check_type,
       routine_name,
       routine_definition
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
  AND (routine_definition LIKE '%expenses.category %'
       OR routine_definition LIKE '%e.category %'
       OR routine_definition LIKE '% category,%'
       OR routine_definition LIKE '%GROUP BY category%');

-- 5. Check for views that might reference "category"
SELECT 'VIEWS' as check_type,
       table_name,
       view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND view_definition LIKE '%category%';
