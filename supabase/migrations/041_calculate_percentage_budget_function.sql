-- Migration: Calculate Percentage Budget Function
-- Feature: Italian Categories and Budget Management (004)
-- RPC function to calculate personal budget from percentage

CREATE OR REPLACE FUNCTION public.calculate_percentage_budget(
  p_group_budget_amount INTEGER,
  p_percentage NUMERIC(5,2)
)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  -- Validate inputs
  IF p_group_budget_amount IS NULL OR p_percentage IS NULL THEN
    RETURN NULL;
  END IF;

  IF p_percentage < 0 OR p_percentage > 100 THEN
    RAISE EXCEPTION 'Percentage must be between 0 and 100';
  END IF;

  IF p_group_budget_amount < 0 THEN
    RAISE EXCEPTION 'Group budget amount cannot be negative';
  END IF;

  -- Calculate: (group_amount * percentage) / 100
  -- Result is already in cents since group_amount is in cents
  RETURN FLOOR((p_group_budget_amount * p_percentage) / 100);
END;
$$;

-- Add comment
COMMENT ON FUNCTION public.calculate_percentage_budget IS
  'Calculates personal budget amount in cents from group budget and percentage (0-100)';
