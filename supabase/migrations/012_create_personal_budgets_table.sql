-- Migration: Create personal_budgets table
-- Feature: Budget Management and Category Customization
-- User Story: US2 - Define Personal Budget
-- Date: 2026-01-01
--
-- Purpose: Store monthly budgets set by individual users for their personal expenses

-- Create personal_budgets table
CREATE TABLE IF NOT EXISTS public.personal_budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount >= 0),
  month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
  year INTEGER NOT NULL CHECK (year >= 2000),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),

  -- One budget per user per month
  UNIQUE(user_id, year, month)
);

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_personal_budgets_lookup
  ON public.personal_budgets(user_id, year, month);

-- Add table comment
COMMENT ON TABLE public.personal_budgets IS
  'Monthly budgets for individual users to track their personal spending (includes both personal expenses and their share of group expenses)';

-- Enable Row Level Security
ALTER TABLE public.personal_budgets ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only manage their own personal budgets
CREATE POLICY "Users can manage their own personal budgets"
  ON public.personal_budgets FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Create trigger to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_personal_budgets_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_personal_budgets_updated_at
  BEFORE UPDATE ON public.personal_budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_personal_budgets_updated_at();
