-- Phase 2: Add NOT NULL constraint to is_group_expense
-- Migration: 020_add_is_group_expense_not_null.sql
--
-- Purpose: Enforce data integrity after all expenses have been migrated
-- Prerequisites: All existing expenses must have is_group_expense = true (from migration 010)
-- Timing: Deploy AFTER app rollout ensures all new expenses have this field

-- First, update any NULL values to true (defensive, should not exist)
UPDATE public.expenses
SET is_group_expense = true
WHERE is_group_expense IS NULL;

-- Add NOT NULL constraint
ALTER TABLE public.expenses
ALTER COLUMN is_group_expense SET NOT NULL;

-- Add comment for documentation
COMMENT ON COLUMN public.expenses.is_group_expense IS
  'Whether the expense is a group expense (visible to all) or personal expense (visible only to creator). NOT NULL enforced after Phase 2 migration.';
