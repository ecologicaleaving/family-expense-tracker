-- Migration: Enable Supabase Realtime on expenses table
-- Feature: Budget Management and Category Customization
-- User Story: US1 - Real-time budget updates
-- Date: 2026-01-01
--
-- Purpose: Enable real-time subscriptions for expense changes to support
-- multi-device budget synchronization

-- Enable realtime for expenses table
ALTER PUBLICATION supabase_realtime ADD TABLE public.expenses;

-- Verify realtime is enabled
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'expenses'
  ) THEN
    RAISE NOTICE 'Realtime enabled successfully for expenses table';
  ELSE
    RAISE WARNING 'Failed to enable realtime for expenses table';
  END IF;
END $$;
