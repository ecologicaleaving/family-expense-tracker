-- Migration: Budget Percentage History Table
-- Feature: Italian Categories and Budget Management (004)
-- Tracks historical changes to budget percentages for audit trail

CREATE TABLE IF NOT EXISTS public.budget_percentage_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_budget_id UUID NOT NULL REFERENCES public.category_budgets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.expense_categories(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  year INTEGER NOT NULL CHECK (year >= 2000 AND year <= 2100),
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  percentage_value NUMERIC(5,2) NOT NULL CHECK (percentage_value >= 0 AND percentage_value <= 100),
  group_budget_amount INTEGER NOT NULL CHECK (group_budget_amount >= 0),
  calculated_amount INTEGER NOT NULL CHECK (calculated_amount >= 0),
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  changed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_budget_percentage_history_budget_id
  ON public.budget_percentage_history(category_budget_id);

CREATE INDEX IF NOT EXISTS idx_budget_percentage_history_user_id
  ON public.budget_percentage_history(user_id);

CREATE INDEX IF NOT EXISTS idx_budget_percentage_history_category_group
  ON public.budget_percentage_history(category_id, group_id, year, month);

CREATE INDEX IF NOT EXISTS idx_budget_percentage_history_changed_at
  ON public.budget_percentage_history(changed_at DESC);

-- Add comments
COMMENT ON TABLE public.budget_percentage_history IS
  'Audit trail for budget percentage changes over time';
COMMENT ON COLUMN public.budget_percentage_history.category_budget_id IS
  'Reference to the category budget that was changed';
COMMENT ON COLUMN public.budget_percentage_history.percentage_value IS
  'The percentage value (0-100) that was set';
COMMENT ON COLUMN public.budget_percentage_history.group_budget_amount IS
  'The group budget amount at the time of change (for historical context)';
COMMENT ON COLUMN public.budget_percentage_history.calculated_amount IS
  'The calculated personal budget amount at the time of change';
