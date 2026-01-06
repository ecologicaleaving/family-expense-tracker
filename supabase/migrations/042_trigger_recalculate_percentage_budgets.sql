-- Migration: Trigger to Recalculate Percentage Budgets
-- Feature: Italian Categories and Budget Management (004)
-- Automatically recalculates personal percentage budgets when group budget changes

-- Create function that will be called by trigger
CREATE OR REPLACE FUNCTION public.recalculate_percentage_budgets()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only proceed if this is a group budget and amount changed
  IF NEW.is_group_budget = true AND NEW.amount != OLD.amount THEN
    -- Update all percentage-based personal budgets for this category/group/month/year
    UPDATE public.category_budgets
    SET
      calculated_amount = public.calculate_percentage_budget(NEW.amount, percentage_of_group),
      updated_at = now()
    WHERE
      category_id = NEW.category_id
      AND group_id = NEW.group_id
      AND year = NEW.year
      AND month = NEW.month
      AND is_group_budget = false
      AND budget_type = 'PERCENTAGE'
      AND percentage_of_group IS NOT NULL;
  END IF;

  RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_recalculate_percentage_budgets ON public.category_budgets;

CREATE TRIGGER trigger_recalculate_percentage_budgets
  AFTER UPDATE OF amount ON public.category_budgets
  FOR EACH ROW
  WHEN (NEW.is_group_budget = true)
  EXECUTE FUNCTION public.recalculate_percentage_budgets();

-- Add comments
COMMENT ON FUNCTION public.recalculate_percentage_budgets IS
  'Trigger function that recalculates all percentage-based personal budgets when group budget changes';
COMMENT ON TRIGGER trigger_recalculate_percentage_budgets ON public.category_budgets IS
  'Automatically recalculates percentage budgets when group budget amount is updated';
