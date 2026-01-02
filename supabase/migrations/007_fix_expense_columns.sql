-- Fix expense table columns to match app expectations
-- Migration: 007_fix_expense_columns.sql

-- Rename user_id to created_by (if it exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expenses' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.expenses RENAME COLUMN user_id TO created_by;
  END IF;
END $$;

-- Rename user_display_name to created_by_name (if it exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expenses' AND column_name = 'user_display_name'
  ) THEN
    ALTER TABLE public.expenses RENAME COLUMN user_display_name TO created_by_name;
  END IF;
END $$;

-- Add paid_by column (if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expenses' AND column_name = 'paid_by'
  ) THEN
    ALTER TABLE public.expenses
      ADD COLUMN paid_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Set paid_by to created_by for existing rows
UPDATE public.expenses
SET paid_by = created_by
WHERE paid_by IS NULL;

-- Add paid_by_name column (if it doesn't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expenses' AND column_name = 'paid_by_name'
  ) THEN
    ALTER TABLE public.expenses
      ADD COLUMN paid_by_name TEXT;
  END IF;
END $$;

-- Set paid_by_name to created_by_name for existing rows
UPDATE public.expenses
SET paid_by_name = created_by_name
WHERE paid_by_name IS NULL;

-- Update index on user_id to use created_by
DROP INDEX IF EXISTS idx_expenses_user_id;
CREATE INDEX IF NOT EXISTS idx_expenses_created_by ON public.expenses(created_by);
CREATE INDEX IF NOT EXISTS idx_expenses_paid_by ON public.expenses(paid_by);

-- Add receipt_url as alias for receipt_image_url if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'expenses' AND column_name = 'receipt_url'
  ) THEN
    ALTER TABLE public.expenses
      RENAME COLUMN receipt_image_url TO receipt_url;
  END IF;
END $$;
