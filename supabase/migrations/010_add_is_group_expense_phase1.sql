-- Migration: Add is_group_expense column to expenses table (Phase 1 - Nullable with default)
-- Feature: Budget Management and Category Customization
-- User Story: US3 - Mark Expenses as Group or Personal
-- Date: 2026-01-01
--
-- Phase 1 Strategy: Add column as nullable with default value for backward compatibility
-- This allows old app versions to continue working while new versions are deployed
-- Phase 2 (separate migration) will add NOT NULL constraint after rollout complete

-- Add is_group_expense column with default true
ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS is_group_expense BOOLEAN DEFAULT true;

-- Backfill existing rows with default value
UPDATE public.expenses
SET is_group_expense = true
WHERE is_group_expense IS NULL;

-- Create index for efficient filtering by expense type
CREATE INDEX IF NOT EXISTS idx_expenses_is_group ON public.expenses(is_group_expense);

-- Add comment for documentation
COMMENT ON COLUMN public.expenses.is_group_expense IS
  'Expense classification: true for group expenses (visible to all members), false for personal expenses (visible only to creator)';
