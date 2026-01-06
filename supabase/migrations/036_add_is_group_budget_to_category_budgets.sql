-- Migration: Add is_group_budget field to category_budgets
-- Feature: Separate budgets for personal and group expenses
-- Allows users to set different budgets for personal vs group spending per category

-- Add is_group_budget column (default true for backward compatibility)
ALTER TABLE public.category_budgets
ADD COLUMN IF NOT EXISTS is_group_budget BOOLEAN NOT NULL DEFAULT true;

-- Drop old unique constraint
ALTER TABLE public.category_budgets
DROP CONSTRAINT IF EXISTS category_budgets_category_id_group_id_year_month_key;

-- Add new unique constraint including is_group_budget
-- This allows one personal budget AND one group budget per category per month
ALTER TABLE public.category_budgets
ADD CONSTRAINT category_budgets_unique_budget
UNIQUE(category_id, group_id, year, month, is_group_budget);

-- Update comment
COMMENT ON COLUMN public.category_budgets.is_group_budget IS
  'True for budgets tracking group expenses, false for budgets tracking personal expenses';

-- Add index for efficient queries
CREATE INDEX IF NOT EXISTS idx_category_budgets_type
ON public.category_budgets(group_id, is_group_budget, year, month);
