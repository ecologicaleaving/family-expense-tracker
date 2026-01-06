-- Migration: RLS Policies for Budget Percentage History
-- Feature: Italian Categories and Budget Management (004)
-- Row Level Security policies for budget_percentage_history table

-- Enable RLS
ALTER TABLE public.budget_percentage_history ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own percentage history
CREATE POLICY "Users can view own percentage history"
  ON public.budget_percentage_history
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR
    group_id = (SELECT group_id FROM public.profiles WHERE id = auth.uid())
  );

-- Policy: Users can insert percentage history when creating/updating their budgets
CREATE POLICY "Users can insert own percentage history"
  ON public.budget_percentage_history
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND
    group_id = (SELECT group_id FROM public.profiles WHERE id = auth.uid())
  );

-- Policy: No updates allowed (history is immutable)
CREATE POLICY "Percentage history is immutable"
  ON public.budget_percentage_history
  FOR UPDATE
  USING (false);

-- Policy: Users can delete their own history (for data cleanup)
CREATE POLICY "Users can delete own percentage history"
  ON public.budget_percentage_history
  FOR DELETE
  USING (user_id = auth.uid());

-- Add comment
COMMENT ON POLICY "Users can view own percentage history" ON public.budget_percentage_history IS
  'Users can view their own percentage history and history from groups they belong to';
COMMENT ON POLICY "Percentage history is immutable" ON public.budget_percentage_history IS
  'History records cannot be modified once created for audit integrity';
