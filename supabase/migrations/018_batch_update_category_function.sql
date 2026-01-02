-- Create PostgreSQL RPC function for batch expense category reassignment
-- Migration: 018_batch_update_category_function.sql
--
-- Purpose: Efficiently reassign all expenses from one category to another
-- Performance: Optimized for 500+ expense batch updates in <1s
-- Used when: Admin deletes a category and needs to reassign expenses

CREATE OR REPLACE FUNCTION batch_update_expense_category(
  p_group_id UUID,
  p_old_category_id TEXT,
  p_new_category_id TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  -- Update all expenses in the group from old category to new category
  UPDATE public.expenses
  SET
    category = p_new_category_id,
    updated_at = NOW()
  WHERE
    group_id = p_group_id
    AND category = p_old_category_id;

  -- Get the number of rows updated
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;

  -- Return the count
  RETURN v_updated_count;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION batch_update_expense_category(UUID, TEXT, TEXT) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION batch_update_expense_category IS
  'Batch update expenses from old category to new category. Returns count of updated expenses.';
