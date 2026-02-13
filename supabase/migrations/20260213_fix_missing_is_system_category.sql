-- Migration: Fix Missing is_system_category Column
-- Date: 2026-02-13
-- Purpose: Ensure is_system_category column exists (migration 053 may not have been applied)
--
-- This migration safely adds the is_system_category column if it's missing,
-- which is required by the DELETE RLS policy "Group admins can delete non-system categories"

-- Add is_system_category flag if it doesn't exist
ALTER TABLE public.expense_categories
ADD COLUMN IF NOT EXISTS is_system_category BOOLEAN DEFAULT false;

-- Mark "Varie" as a system category (if it exists)
UPDATE public.expense_categories
SET is_system_category = true
WHERE name = 'Varie' AND is_default = true AND is_system_category = false;

-- Ensure the index exists
CREATE INDEX IF NOT EXISTS idx_expense_categories_system
ON public.expense_categories(is_system_category)
WHERE is_system_category = true;

-- Add comment if column was just created
COMMENT ON COLUMN public.expense_categories.is_system_category IS
'Flag indicating this is a system-managed category (like "Varie"/"Other") that cannot be deleted. System categories are used for special purposes like catch-all for uncategorized expenses.';

-- Ensure the correct DELETE policy exists
-- This recreates the policy to handle cases where it may have been created with wrong dependencies
DO $$
BEGIN
    -- Drop any existing delete policies
    DROP POLICY IF EXISTS "Group admins can delete non-default categories" ON public.expense_categories;
    DROP POLICY IF EXISTS "Group admins can delete non-system categories" ON public.expense_categories;

    -- Create the correct delete policy
    CREATE POLICY "Group admins can delete non-system categories"
    ON public.expense_categories
    FOR DELETE
    TO authenticated
    USING (
        is_system_category = false
        AND is_default = false
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
            AND group_id = expense_categories.group_id
            AND is_group_admin = true
        )
    );
END $$;
