-- Fix RLS policies to use created_by instead of user_id
-- Migration: 009_fix_rls_policies_created_by.sql

-- Step 1: Drop old policies that reference user_id
DO $$
BEGIN
    DROP POLICY IF EXISTS "Creators can update own expenses" ON public.expenses;
    DROP POLICY IF EXISTS "Creators can delete own expenses" ON public.expenses;
END $$;

-- Step 2: Recreate policies with correct column name (created_by)
CREATE POLICY "Creators can update own expenses"
    ON public.expenses FOR UPDATE
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "Creators can delete own expenses"
    ON public.expenses FOR DELETE
    USING (created_by = auth.uid());
