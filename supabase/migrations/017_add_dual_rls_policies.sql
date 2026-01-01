-- Add dual RLS policies for group and personal expense privacy
-- Migration: 017_add_dual_rls_policies.sql
--
-- Purpose: Replace single SELECT policy with dual policies:
--   1. Group expenses: Visible to all group members
--   2. Personal expenses: Only visible to creator
--
-- This enables privacy for personal expenses while maintaining group visibility

-- Drop the existing single SELECT policy
DROP POLICY IF EXISTS "Group members can view expenses" ON public.expenses;

-- Create dual SELECT policies

-- Policy 1: Group expenses are visible to all group members
CREATE POLICY "Group members can view group expenses"
    ON public.expenses FOR SELECT
    USING (
        is_group_expense = true AND
        group_id = public.get_my_group_id()
    );

-- Policy 2: Personal expenses are only visible to their creator
CREATE POLICY "Creators can view personal expenses"
    ON public.expenses FOR SELECT
    USING (
        is_group_expense = false AND
        created_by = auth.uid()
    );

-- Note: The existing INSERT, UPDATE, and DELETE policies remain unchanged
-- They already enforce proper authorization based on group membership and ownership
