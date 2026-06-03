-- Crew Up Supabase Storage setup
-- Run crewup_official_site/supabase_schema.sql first.
-- Then run this file in the Supabase SQL Editor.

-- Create or normalize the private Storage bucket used by app.html uploads.
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('crew-files', 'crew-files', false, 52428800)
ON CONFLICT (id) DO UPDATE
SET
  name = EXCLUDED.name,
  public = false,
  file_size_limit = EXCLUDED.file_size_limit;

-- crew-files bucket objects are readable only by crew members.
-- Object paths must start with the crew id: {crew_id}/{filename}
DROP POLICY IF EXISTS "crew-files: members can read objects" ON storage.objects;
CREATE POLICY "crew-files: members can read objects"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'crew-files'
    AND public.is_crew_member((storage.foldername(name))[1]::uuid)
  );

-- Crew members can upload into their own crew folder only.
DROP POLICY IF EXISTS "crew-files: members can upload objects" ON storage.objects;
CREATE POLICY "crew-files: members can upload objects"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'crew-files'
    AND auth.uid() IS NOT NULL
    AND public.is_crew_member((storage.foldername(name))[1]::uuid)
  );

-- Uploader or crew owner can delete the object.
DROP POLICY IF EXISTS "crew-files: uploader or owner can delete objects" ON storage.objects;
CREATE POLICY "crew-files: uploader or owner can delete objects"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'crew-files'
    AND (
      owner = auth.uid()
      OR public.is_crew_owner((storage.foldername(name))[1]::uuid)
    )
  );
