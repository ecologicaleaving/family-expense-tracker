-- Performance Optimization: Add indexes for budget queries
-- Migration: 021_add_performance_indexes.sql
--
-- Purpose: Optimize budget calculation queries for groups with 1000+ expenses
-- Target: <500ms query time for budget stats calculation

-- Index for group budget calculations (group expenses by date)
-- Covers: WHERE group_id = X AND is_group_expense = true AND date >= Y AND date <= Z
CREATE INDEX IF NOT EXISTS idx_expenses_group_budget
ON public.expenses (group_id, is_group_expense, date)
WHERE is_group_expense = true;

-- Index for personal budget calculations (user's expenses by date)
-- Covers: WHERE created_by = X AND date >= Y AND date <= Z
CREATE INDEX IF NOT EXISTS idx_expenses_personal_budget
ON public.expenses (created_by, date);

-- Index for category expense counts
-- Covers: WHERE category = X (used in deletion validation)
CREATE INDEX IF NOT EXISTS idx_expenses_category
ON public.expenses (category);

-- Index for budget table lookups by group and month
CREATE INDEX IF NOT EXISTS idx_group_budgets_lookup
ON public.group_budgets (group_id, year, month);

-- Index for personal budget table lookups by user and month
CREATE INDEX IF NOT EXISTS idx_personal_budgets_lookup
ON public.personal_budgets (user_id, year, month);

-- Index for category lookups by group
CREATE INDEX IF NOT EXISTS idx_expense_categories_group
ON public.expense_categories (group_id, is_default);

-- Add comments for documentation
COMMENT ON INDEX idx_expenses_group_budget IS
  'Optimizes group budget calculation queries filtering by group_id, is_group_expense, and date range';

COMMENT ON INDEX idx_expenses_personal_budget IS
  'Optimizes personal budget calculation queries filtering by created_by and date range';

COMMENT ON INDEX idx_expenses_category IS
  'Optimizes category expense count queries for deletion validation';

COMMENT ON INDEX idx_group_budgets_lookup IS
  'Optimizes group budget retrieval by group_id, year, and month';

COMMENT ON INDEX idx_personal_budgets_lookup IS
  'Optimizes personal budget retrieval by user_id, year, and month';

COMMENT ON INDEX idx_expense_categories_group IS
  'Optimizes category list retrieval by group_id with default/custom filtering';
