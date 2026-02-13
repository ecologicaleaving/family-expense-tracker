-- Add is_active column to expense_categories
-- This allows categories to be deactivated without deletion
-- Inactive categories are hidden from selection but preserved in historical data

-- Add is_active column
ALTER TABLE public.expense_categories
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Documentation
COMMENT ON COLUMN public.expense_categories.is_active IS
  'Whether the category is active and available for new expenses. Inactive categories are hidden from selection but preserved in historical data.';

-- Partial index for performance (only index active categories)
CREATE INDEX IF NOT EXISTS idx_expense_categories_is_active
  ON public.expense_categories(is_active)
  WHERE is_active = TRUE;

-- Set existing categories to active
UPDATE public.expense_categories
  SET is_active = TRUE
  WHERE is_active IS NULL;
