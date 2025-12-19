-- Migration: Create storage buckets for receipt images
-- This migration creates the 'receipts' bucket and sets up RLS policies

-- Create the receipts bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'receipts',
  'receipts',
  false,
  5242880, -- 5MB max file size
  ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Policy: Users can upload receipts to their own folder
CREATE POLICY "Users can upload own receipts"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can view receipts from their group
CREATE POLICY "Users can view group receipts"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'receipts'
  AND EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
    AND p.group_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.expenses e
      WHERE e.receipt_url LIKE '%' || storage.objects.name
      AND e.group_id = p.group_id
    )
  )
);

-- Policy: Users can update their own receipts
CREATE POLICY "Users can update own receipts"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy: Users can delete their own receipts
CREATE POLICY "Users can delete own receipts"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'receipts'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Function to generate signed URLs for receipts
-- (This is typically called from the application, but we can create a helper function)
CREATE OR REPLACE FUNCTION public.get_receipt_signed_url(receipt_path TEXT, expiry_seconds INT DEFAULT 3600)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  signed_url TEXT;
BEGIN
  -- Check if user has access to this receipt
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    JOIN public.expenses e ON e.group_id = p.group_id
    WHERE p.id = auth.uid()
    AND e.receipt_url LIKE '%' || receipt_path
  ) THEN
    RAISE EXCEPTION 'Access denied to receipt';
  END IF;

  -- Generate signed URL (this is a placeholder - actual implementation uses Supabase client)
  -- In practice, signed URLs are generated client-side using the Supabase SDK
  RETURN NULL;
END;
$$;
