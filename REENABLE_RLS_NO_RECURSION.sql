-- Re-enable RLS with SIMPLIFIED policies to avoid recursion
-- Run this AFTER the Storage policies are fixed

-- ============================================
-- HELPER FUNCTION to avoid recursion
-- ============================================
-- Create a security definer function to get user's group_id
CREATE OR REPLACE FUNCTION public.user_group_id()
RETURNS uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT group_id FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$;

-- ============================================
-- PROFILES
-- ============================================
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view group members" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Simple policy: users can only view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- ============================================
-- EXPENSES
-- ============================================
-- Drop existing policies first
DROP POLICY IF EXISTS "Group members can view expenses" ON public.expenses;
DROP POLICY IF EXISTS "Group members can create expenses" ON public.expenses;
DROP POLICY IF EXISTS "Creators can update own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Creators can delete own expenses" ON public.expenses;
DROP POLICY IF EXISTS "Admins can delete group expenses" ON public.expenses;

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Use the helper function to avoid recursion
CREATE POLICY "Group members can view expenses"
    ON public.expenses FOR SELECT
    TO authenticated
    USING (group_id = public.user_group_id());

CREATE POLICY "Group members can create expenses"
    ON public.expenses FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND created_by = auth.uid()
        AND group_id = public.user_group_id()
    );

CREATE POLICY "Creators can update own expenses"
    ON public.expenses FOR UPDATE
    TO authenticated
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "Creators can delete own expenses"
    ON public.expenses FOR DELETE
    TO authenticated
    USING (created_by = auth.uid());

-- Note: Admins can delete policy removed to simplify - only creators can delete for now

-- ============================================
-- FAMILY GROUPS
-- ============================================
-- Drop existing policies first
DROP POLICY IF EXISTS "Members can view their group" ON public.family_groups;
DROP POLICY IF EXISTS "Authenticated users can create groups" ON public.family_groups;
DROP POLICY IF EXISTS "Admins can update their group" ON public.family_groups;
DROP POLICY IF EXISTS "Admins can delete their group" ON public.family_groups;

ALTER TABLE public.family_groups ENABLE ROW LEVEL SECURITY;

-- Use the helper function to avoid recursion
CREATE POLICY "Members can view their group"
    ON public.family_groups FOR SELECT
    TO authenticated
    USING (id = public.user_group_id());

CREATE POLICY "Authenticated users can create groups"
    ON public.family_groups FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() IS NOT NULL);

-- Simplified: any group member can update (we'll refine later if needed)
CREATE POLICY "Members can update their group"
    ON public.family_groups FOR UPDATE
    TO authenticated
    USING (id = public.user_group_id());

-- Simplified: any group member can delete (we'll refine later if needed)
CREATE POLICY "Members can delete their group"
    ON public.family_groups FOR DELETE
    TO authenticated
    USING (id = public.user_group_id());

-- ============================================
-- INVITES
-- ============================================
-- Drop existing policies first
DROP POLICY IF EXISTS "Anyone can validate invite codes" ON public.invites;
DROP POLICY IF EXISTS "Admins can create invites" ON public.invites;
DROP POLICY IF EXISTS "Admins can update invites" ON public.invites;
DROP POLICY IF EXISTS "Users can use invites" ON public.invites;
DROP POLICY IF EXISTS "Admins can delete invites" ON public.invites;

ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can validate invite codes"
    ON public.invites FOR SELECT
    TO authenticated
    USING (true);

-- Simplified: any group member can create invites
CREATE POLICY "Group members can create invites"
    ON public.invites FOR INSERT
    TO authenticated
    WITH CHECK (group_id = public.user_group_id());

-- Simplified: any group member can update invites
CREATE POLICY "Group members can update invites"
    ON public.invites FOR UPDATE
    TO authenticated
    USING (group_id = public.user_group_id());

CREATE POLICY "Users can use invites"
    ON public.invites FOR UPDATE
    TO authenticated
    USING (
        auth.uid() IS NOT NULL
        AND used_at IS NULL
        AND expires_at > NOW()
    )
    WITH CHECK (
        used_by = auth.uid()
        AND used_at IS NOT NULL
    );

-- Simplified: any group member can delete invites
CREATE POLICY "Group members can delete invites"
    ON public.invites FOR DELETE
    TO authenticated
    USING (group_id = public.user_group_id());
