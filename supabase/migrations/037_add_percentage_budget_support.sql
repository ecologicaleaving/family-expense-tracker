-- Migration: Add Percentage Budget Support
-- Feature: Italian Categories and Budget Management (004)
-- Adds support for percentage-based personal budgets

-- Add new columns to category_budgets table
ALTER TABLE public.category_budgets
ADD COLUMN IF NOT EXISTS budget_type TEXT NOT NULL DEFAULT 'FIXED'
  CHECK (budget_type IN ('FIXED', 'PERCENTAGE')),
ADD COLUMN IF NOT EXISTS percentage_of_group NUMERIC(5,2)
  CHECK (percentage_of_group IS NULL OR (percentage_of_group >= 0 AND percentage_of_group <= 100)),
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS calculated_amount INTEGER
  CHECK (calculated_amount IS NULL OR calculated_amount >= 0);

-- Add check constraints to ensure data integrity
ALTER TABLE public.category_budgets
ADD CONSTRAINT check_group_budget_no_user
  CHECK (is_group_budget = true AND user_id IS NULL OR is_group_budget = false),
ADD CONSTRAINT check_personal_budget_has_user
  CHECK (is_group_budget = false AND user_id IS NOT NULL OR is_group_budget = true),
ADD CONSTRAINT check_percentage_type_has_percentage
  CHECK (budget_type = 'PERCENTAGE' AND percentage_of_group IS NOT NULL OR budget_type = 'FIXED'),
ADD CONSTRAINT check_percentage_type_has_calculated
  CHECK (budget_type = 'PERCENTAGE' AND calculated_amount IS NOT NULL OR budget_type = 'FIXED');

-- Drop the old unique constraint and create new one that includes user_id
ALTER TABLE public.category_budgets
DROP CONSTRAINT IF EXISTS category_budgets_unique_budget;

ALTER TABLE public.category_budgets
ADD CONSTRAINT category_budgets_unique_budget
UNIQUE(category_id, group_id, year, month, is_group_budget, user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_category_budgets_user_id
  ON public.category_budgets(user_id) WHERE user_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_category_budgets_budget_type
  ON public.category_budgets(budget_type);

CREATE INDEX IF NOT EXISTS idx_category_budgets_group_lookup
  ON public.category_budgets(category_id, group_id, year, month, is_group_budget);

-- Add comment
COMMENT ON COLUMN public.category_budgets.budget_type IS
  'Type of budget: FIXED (fixed euro amount) or PERCENTAGE (percentage of group budget)';
COMMENT ON COLUMN public.category_budgets.percentage_of_group IS
  'Percentage (0-100) of group budget for PERCENTAGE type budgets';
COMMENT ON COLUMN public.category_budgets.user_id IS
  'User ID for personal budgets (NULL for group budgets)';
COMMENT ON COLUMN public.category_budgets.calculated_amount IS
  'Auto-calculated amount in cents for PERCENTAGE type budgets';
