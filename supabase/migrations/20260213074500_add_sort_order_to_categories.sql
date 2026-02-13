-- Migration: Add sort_order to expense_categories
-- Date: 2026-02-13
-- Purpose: Enable custom sorting for expense categories

-- Add sort_order column to expense_categories table
ALTER TABLE public.expense_categories
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

-- Update comment for documentation
COMMENT ON COLUMN public.expense_categories.sort_order IS
  'Custom sorting order for categories (lower values appear first).';

-- Create an index for faster sorting if needed
CREATE INDEX IF NOT EXISTS idx_expense_categories_sort_order
  ON public.expense_categories(sort_order);
