-- Migration: Add PDF MIME type to receipts bucket
-- This migration updates the 'receipts' bucket to allow PDF file uploads

-- Update the receipts bucket to include application/pdf in allowed MIME types
UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']::text[]
WHERE id = 'receipts';
