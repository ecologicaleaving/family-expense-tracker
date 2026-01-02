-- Create PostgreSQL RPC function to get expense count for a category
-- Migration: 019_get_expense_count_by_category_function.sql
--
-- Purpose: Get the number of expenses using a specific category
-- Performance: Optimized with category index
-- Used when: Displaying category usage, validating deletion

CREATE OR REPLACE FUNCTION get_category_expense_count(
  p_category_id TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Count expenses using this category
  SELECT COUNT(*)
  INTO v_count
  FROM public.expenses
  WHERE category = p_category_id;

  -- Return the count
  RETURN COALESCE(v_count, 0);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_category_expense_count(TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_category_expense_count IS
  'Get the number of expenses using a specific category. Returns 0 if category has no expenses.';
