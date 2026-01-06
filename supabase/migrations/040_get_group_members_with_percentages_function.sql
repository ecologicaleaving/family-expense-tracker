-- Migration: Get Group Members With Percentages Function
-- Feature: Italian Categories and Budget Management (004)
-- RPC function to retrieve members and their budget percentages

CREATE OR REPLACE FUNCTION public.get_group_members_with_percentages(
  p_group_id UUID,
  p_category_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE (
  user_id UUID,
  user_name TEXT,
  user_email TEXT,
  percentage_value NUMERIC(5,2),
  calculated_amount INTEGER,
  budget_type TEXT
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
    AND id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User does not have access to this group';
  END IF;

  -- Return members with their percentage budgets for this category
  RETURN QUERY
  SELECT
    p.id AS user_id,
    p.display_name AS user_name,
    p.email AS user_email,
    cb.percentage_of_group AS percentage_value,
    cb.calculated_amount,
    cb.budget_type
  FROM public.profiles p
  LEFT JOIN public.category_budgets cb ON
    cb.user_id = p.id
    AND cb.category_id = p_category_id
    AND cb.group_id = p_group_id
    AND cb.year = p_year
    AND cb.month = p_month
    AND cb.is_group_budget = false
    AND cb.budget_type = 'PERCENTAGE'
  WHERE p.group_id = p_group_id
  ORDER BY p.display_name;
END;
$$;

-- Add comment
COMMENT ON FUNCTION public.get_group_members_with_percentages IS
  'Returns list of group members with their percentage-based budgets for a specific category and month';
