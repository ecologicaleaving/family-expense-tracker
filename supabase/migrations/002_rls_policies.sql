-- Family Expense Tracker - Row Level Security Policies
-- Migration: 002_rls_policies.sql

-- ============================================
-- PROFILES
-- ============================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

-- Users can view other members of their group
CREATE POLICY "Users can view group members"
    ON public.profiles FOR SELECT
    USING (
        group_id IS NOT NULL AND
        group_id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid())
    );

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Profile insert is handled by trigger, no direct insert needed

-- ============================================
-- FAMILY GROUPS
-- ============================================
ALTER TABLE public.family_groups ENABLE ROW LEVEL SECURITY;

-- Members can view their group
CREATE POLICY "Members can view their group"
    ON public.family_groups FOR SELECT
    USING (id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid()));

-- Authenticated users can create groups
CREATE POLICY "Authenticated users can create groups"
    ON public.family_groups FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Admins can update their group
CREATE POLICY "Admins can update their group"
    ON public.family_groups FOR UPDATE
    USING (
        id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- Admins can delete their group (only if they're the last admin)
CREATE POLICY "Admins can delete their group"
    ON public.family_groups FOR DELETE
    USING (
        id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- ============================================
-- EXPENSES
-- ============================================
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- Group members can view all group expenses
CREATE POLICY "Group members can view expenses"
    ON public.expenses FOR SELECT
    USING (
        group_id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid())
    );

-- Group members can create expenses in their group
CREATE POLICY "Group members can create expenses"
    ON public.expenses FOR INSERT
    WITH CHECK (
        group_id IN (SELECT group_id FROM public.profiles WHERE id = auth.uid())
    );

-- Creators can update their own expenses
CREATE POLICY "Creators can update own expenses"
    ON public.expenses FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Creators can delete their own expenses
CREATE POLICY "Creators can delete own expenses"
    ON public.expenses FOR DELETE
    USING (user_id = auth.uid());

-- Admins can delete any expense in their group
CREATE POLICY "Admins can delete group expenses"
    ON public.expenses FOR DELETE
    USING (
        group_id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- ============================================
-- INVITES
-- ============================================
ALTER TABLE public.invites ENABLE ROW LEVEL SECURITY;

-- Anyone can validate invite codes (needed for joining)
CREATE POLICY "Anyone can validate invite codes"
    ON public.invites FOR SELECT
    USING (true);

-- Admins can create invites for their group
CREATE POLICY "Admins can create invites"
    ON public.invites FOR INSERT
    WITH CHECK (
        group_id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- Admins can update invites (mark as used)
CREATE POLICY "Admins can update invites"
    ON public.invites FOR UPDATE
    USING (
        group_id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- Authenticated users can mark invite as used (when joining)
CREATE POLICY "Users can use invites"
    ON public.invites FOR UPDATE
    USING (
        auth.uid() IS NOT NULL AND
        used_at IS NULL AND
        expires_at > NOW()
    )
    WITH CHECK (
        used_by = auth.uid() AND
        used_at IS NOT NULL
    );

-- Admins can delete invites
CREATE POLICY "Admins can delete invites"
    ON public.invites FOR DELETE
    USING (
        group_id IN (
            SELECT group_id FROM public.profiles
            WHERE id = auth.uid() AND is_group_admin = true
        )
    );

-- ============================================
-- STORAGE (for receipt images)
-- ============================================
-- Note: Run these in the Supabase dashboard under Storage > Policies

-- CREATE POLICY "Users can upload receipts"
--     ON storage.objects FOR INSERT
--     WITH CHECK (
--         bucket_id = 'receipts' AND
--         auth.uid() IS NOT NULL
--     );

-- CREATE POLICY "Users can view receipts in their group"
--     ON storage.objects FOR SELECT
--     USING (
--         bucket_id = 'receipts' AND
--         auth.uid() IS NOT NULL
--     );
