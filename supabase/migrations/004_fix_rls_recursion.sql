-- Fix RLS infinite recursion in profiles table
-- Migration: 004_fix_rls_recursion.sql

-- Drop the problematic policy that causes recursion
DROP POLICY IF EXISTS "Users can view group members" ON public.profiles;

-- Create a security definer function to get user's group_id without RLS
CREATE OR REPLACE FUNCTION public.get_my_group_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT group_id FROM public.profiles WHERE id = auth.uid();
$$;

-- Recreate the policy using the function (avoids recursion)
CREATE POLICY "Users can view group members"
    ON public.profiles FOR SELECT
    USING (
        group_id IS NOT NULL AND
        group_id = public.get_my_group_id()
    );

-- Also fix family_groups policies that have the same issue
DROP POLICY IF EXISTS "Members can view their group" ON public.family_groups;
CREATE POLICY "Members can view their group"
    ON public.family_groups FOR SELECT
    USING (id = public.get_my_group_id());

DROP POLICY IF EXISTS "Admins can update their group" ON public.family_groups;
CREATE POLICY "Admins can update their group"
    ON public.family_groups FOR UPDATE
    USING (
        id = public.get_my_group_id() AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_group_admin = true)
    );

DROP POLICY IF EXISTS "Admins can delete their group" ON public.family_groups;
CREATE POLICY "Admins can delete their group"
    ON public.family_groups FOR DELETE
    USING (
        id = public.get_my_group_id() AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_group_admin = true)
    );

-- Fix expenses policies
DROP POLICY IF EXISTS "Group members can view expenses" ON public.expenses;
CREATE POLICY "Group members can view expenses"
    ON public.expenses FOR SELECT
    USING (group_id = public.get_my_group_id());

DROP POLICY IF EXISTS "Group members can create expenses" ON public.expenses;
CREATE POLICY "Group members can create expenses"
    ON public.expenses FOR INSERT
    WITH CHECK (group_id = public.get_my_group_id());

DROP POLICY IF EXISTS "Admins can delete group expenses" ON public.expenses;
CREATE POLICY "Admins can delete group expenses"
    ON public.expenses FOR DELETE
    USING (
        group_id = public.get_my_group_id() AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_group_admin = true)
    );

-- Fix invites policies
DROP POLICY IF EXISTS "Admins can create invites" ON public.invites;
CREATE POLICY "Admins can create invites"
    ON public.invites FOR INSERT
    WITH CHECK (
        group_id = public.get_my_group_id() AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_group_admin = true)
    );

DROP POLICY IF EXISTS "Admins can update invites" ON public.invites;
CREATE POLICY "Admins can update invites"
    ON public.invites FOR UPDATE
    USING (
        group_id = public.get_my_group_id() AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_group_admin = true)
    );

DROP POLICY IF EXISTS "Admins can delete invites" ON public.invites;
CREATE POLICY "Admins can delete invites"
    ON public.invites FOR DELETE
    USING (
        group_id = public.get_my_group_id() AND
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_group_admin = true)
    );
