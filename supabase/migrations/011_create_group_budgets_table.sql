-- Migration: Create group_budgets table
-- Feature: Budget Management and Category Customization
-- User Story: US1 - Define Group Budget
-- Date: 2026-01-01
--
-- Purpose: Store monthly budgets set by group administrators

-- Create group_budgets table
CREATE TABLE IF NOT EXISTS public.group_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  created_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- One budget per group per month
  UNIQUE(group_id, year, month)
);

-- Create indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_group_budgets_lookup
  ON public.group_budgets(group_id, year, month);

CREATE INDEX IF NOT EXISTS idx_group_budgets_created_by
  ON public.group_budgets(created_by);

-- Add table comment
COMMENT ON TABLE public.group_budgets IS
  'Monthly budgets for family groups, set by group administrators';

-- Enable Row Level Security
ALTER TABLE public.group_budgets ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Group members can view their group budgets
CREATE POLICY "Users can view their group budgets"
  ON public.group_budgets FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM public.profiles WHERE id = auth.uid()
    )
  );

-- RLS Policy: Only group admins can create/update group budgets
CREATE POLICY "Group admins can manage group budgets"
  ON public.group_budgets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND group_id = group_budgets.group_id
        AND is_group_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND group_id = group_budgets.group_id
        AND is_group_admin = true
    )
  );

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_group_budgets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_group_budgets_updated_at
  BEFORE UPDATE ON public.group_budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_group_budgets_updated_at();
