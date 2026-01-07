-- Migration: Remove duplicate category budgets
-- Some categories may have duplicate budget entries due to manual resets
-- before the cents conversion migration. This keeps only the most recent budget.

-- Delete duplicate category_budgets, keeping only the most recent one per category/group/month/year
DELETE FROM public.category_budgets
WHERE id NOT IN (
  SELECT DISTINCT ON (category_id, group_id, year, month) id
  FROM public.category_budgets
  ORDER BY category_id, group_id, year, month, created_at DESC
);

-- The UNIQUE constraint should prevent future duplicates, but let's verify it exists
-- If it doesn't exist, this will fail silently (DO block)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'category_budgets_category_id_group_id_year_month_key'
  ) THEN
    -- Add unique constraint if it doesn't exist
    ALTER TABLE public.category_budgets
    ADD CONSTRAINT category_budgets_category_id_group_id_year_month_key
    UNIQUE (category_id, group_id, year, month);
  END IF;
END $$;

COMMENT ON TABLE public.category_budgets IS 'Monthly budget allocations per category per group. Duplicates removed in migration 046.';
