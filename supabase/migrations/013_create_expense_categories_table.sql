-- Migration: Create expense_categories table and add category_id to expenses
-- Feature: Budget Management and Category Customization
-- User Story: US4 - Customize Expense Categories
-- Date: 2026-01-01
--
-- Purpose: Enable customizable expense categories managed by group administrators

-- Create expense_categories table
CREATE TABLE IF NOT EXISTS public.expense_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL,
  group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- Category names must be unique within a group
  UNIQUE(group_id, name)
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_expense_categories_group
  ON public.expense_categories(group_id);

CREATE INDEX IF NOT EXISTS idx_expense_categories_name
  ON public.expense_categories(group_id, name);

-- Add table comment
COMMENT ON TABLE public.expense_categories IS
  'Customizable expense categories for organizing expenses. Default categories (Food, Utilities, etc.) cannot be deleted.';

-- Enable Row Level Security
ALTER TABLE public.expense_categories ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Group members can view their group categories
CREATE POLICY "Users can view their group categories"
  ON public.expense_categories FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM public.profiles WHERE id = auth.uid()
    )
  );

-- RLS Policy: Only group admins can create categories
CREATE POLICY "Group admins can create categories"
  ON public.expense_categories FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND group_id = expense_categories.group_id
        AND is_group_admin = true
    )
  );

-- RLS Policy: Only group admins can update categories
CREATE POLICY "Group admins can update categories"
  ON public.expense_categories FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND group_id = expense_categories.group_id
        AND is_group_admin = true
    )
  );

-- RLS Policy: Only group admins can delete non-default categories
CREATE POLICY "Group admins can delete non-default categories"
  ON public.expense_categories FOR DELETE
  USING (
    is_default = false
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND group_id = expense_categories.group_id
        AND is_group_admin = true
    )
  );

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_expense_categories_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_expense_categories_updated_at
  BEFORE UPDATE ON public.expense_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_expense_categories_updated_at();

-- Add category_id foreign key to expenses table
ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES public.expense_categories(id) ON DELETE SET NULL;

-- Create index on category_id for fast lookups
CREATE INDEX IF NOT EXISTS idx_expenses_category
  ON public.expenses(category_id);

-- Add comment for documentation
COMMENT ON COLUMN public.expenses.category_id IS
  'Foreign key to expense_categories table. Replaces old string category field.';
