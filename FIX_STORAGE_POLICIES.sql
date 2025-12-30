-- Fix Storage policies - simplify the complex SELECT policy

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view group receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own receipts" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own receipts" ON storage.objects;

-- CREATE: Allow authenticated users to upload to receipts bucket
CREATE POLICY "Users can upload receipts"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'receipts');

-- SELECT: Allow authenticated users to view receipts (simplified)
CREATE POLICY "Users can view receipts"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'receipts');

-- UPDATE: Allow users to update their own receipts
CREATE POLICY "Users can update own receipts"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (
        bucket_id = 'receipts'
        AND (storage.foldername(name))[1] = (auth.uid())::text
    );

-- DELETE: Allow users to delete their own receipts
CREATE POLICY "Users can delete own receipts"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (
        bucket_id = 'receipts'
        AND (storage.foldername(name))[1] = (auth.uid())::text
    );
