-- Migration: Get Budget Change Notifications Function
-- Feature: Italian Categories and Budget Management (004)
-- RPC function to retrieve notifications about budget changes affecting user

CREATE OR REPLACE FUNCTION public.get_budget_change_notifications(
  p_group_id UUID,
  p_year INTEGER,
  p_month INTEGER,
  p_user_id UUID DEFAULT auth.uid()
)
RETURNS TABLE (
  category_id UUID,
  category_name TEXT,
  old_group_budget INTEGER,
  new_group_budget INTEGER,
  old_personal_budget INTEGER,
  new_personal_budget INTEGER,
  percentage_value NUMERIC(5,2),
  changed_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Check if user has access to this group
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE group_id = p_group_id
    AND id = p_user_id
  ) THEN
    RAISE EXCEPTION 'User does not have access to this group';
  END IF;

  -- Return notifications for percentage budgets that were affected by group budget changes
  RETURN QUERY
  WITH current_budgets AS (
    SELECT
      cb.category_id,
      ec.name AS category_name,
      cb.calculated_amount AS new_personal_budget,
      cb.percentage_of_group AS percentage_value
    FROM public.category_budgets cb
    INNER JOIN public.expense_categories ec ON ec.id = cb.category_id
    WHERE
      cb.group_id = p_group_id
      AND cb.year = p_year
      AND cb.month = p_month
      AND cb.user_id = p_user_id
      AND cb.is_group_budget = false
      AND cb.budget_type = 'PERCENTAGE'
  ),
  latest_history AS (
    SELECT DISTINCT ON (bph.category_id)
      bph.category_id,
      bph.group_budget_amount AS old_group_budget,
      bph.calculated_amount AS old_personal_budget,
      bph.changed_at
    FROM public.budget_percentage_history bph
    WHERE
      bph.group_id = p_group_id
      AND bph.year = p_year
      AND bph.month = p_month
      AND bph.user_id = p_user_id
    ORDER BY bph.category_id, bph.changed_at DESC
  ),
  current_group_budgets AS (
    SELECT
      cb.category_id,
      cb.amount AS new_group_budget
    FROM public.category_budgets cb
    WHERE
      cb.group_id = p_group_id
      AND cb.year = p_year
      AND cb.month = p_month
      AND cb.is_group_budget = true
  )
  SELECT
    cb.category_id,
    cb.category_name,
    lh.old_group_budget,
    cgb.new_group_budget,
    lh.old_personal_budget,
    cb.new_personal_budget,
    cb.percentage_value,
    lh.changed_at
  FROM current_budgets cb
  LEFT JOIN latest_history lh ON lh.category_id = cb.category_id
  INNER JOIN current_group_budgets cgb ON cgb.category_id = cb.category_id
  WHERE
    lh.old_group_budget IS NOT NULL
    AND cgb.new_group_budget != lh.old_group_budget
    AND cb.new_personal_budget != lh.old_personal_budget
  ORDER BY cb.category_name;
END;
$$;

-- Add comment
COMMENT ON FUNCTION public.get_budget_change_notifications IS
  'Returns notifications about group budget changes that affected user''s percentage-based personal budgets';
