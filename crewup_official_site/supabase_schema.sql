-- CrewUp Supabase Schema
-- Run this in the Supabase SQL Editor (Project → SQL Editor → New query)
-- Safe to re-run during development. Tables are preserved; RLS policies are
-- dropped and recreated so policy edits can be applied repeatedly.

-- ────────────────────────────────────────────────────────────────
-- Helper: current user's id
-- ────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auth_uid() RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT auth.uid();
$$;

-- ────────────────────────────────────────────────────────────────
-- 1. profiles
--    Auto-created for every new auth.users row via trigger.
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  avatar_url   text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'display_name', ''),
      NULLIF(NEW.raw_user_meta_data->>'nickname', ''),
      NEW.email
    )
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ────────────────────────────────────────────────────────────────
-- 2. crews
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crews (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  description text,
  category    text,          -- '개발', '디자인', '마케팅', etc.
  is_public   boolean NOT NULL DEFAULT true,
  owner_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS portfolio_message text;
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS portfolio_style text;
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS portfolio_tags text[] NOT NULL DEFAULT '{}';
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS portfolio_video_url text;
ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS portfolio_image_urls jsonb NOT NULL DEFAULT '[]'::jsonb;

-- ────────────────────────────────────────────────────────────────
-- 3. crew_members
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crew_members (
  crew_id     uuid NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role        text NOT NULL DEFAULT 'member', -- 'owner' | 'member'
  can_files   boolean NOT NULL DEFAULT true,
  can_photos  boolean NOT NULL DEFAULT true,
  can_videos  boolean NOT NULL DEFAULT false,
  joined_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (crew_id, user_id)
);

-- ────────────────────────────────────────────────────────────────
-- 4. join_requests
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.join_requests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id     uuid NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message     text,
  status      text NOT NULL DEFAULT 'pending', -- 'pending' | 'approved' | 'rejected'
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (crew_id, user_id)
);

-- ────────────────────────────────────────────────────────────────
-- 5. crew_messages  (simple chat)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crew_messages (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id     uuid NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body        text NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────────
-- 6. crew_notes
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crew_notes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id     uuid NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
  author_id   uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title       text NOT NULL DEFAULT '',
  body        text NOT NULL DEFAULT '',
  updated_at  timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────────
-- 7. crew_links
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crew_links (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id     uuid NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
  added_by    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  url         text NOT NULL,
  label       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ────────────────────────────────────────────────────────────────
-- 8. crew_files  (metadata; actual blobs live in Storage)
-- ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.crew_files (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  crew_id      uuid NOT NULL REFERENCES public.crews(id) ON DELETE CASCADE,
  uploaded_by  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  storage_path text NOT NULL,   -- path inside the 'crew-files' bucket
  filename     text NOT NULL,
  mime_type    text,
  size_bytes   bigint,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════
-- Row-Level Security
-- ════════════════════════════════════════════════════════════════

ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crews         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_members  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_notes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_links    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.crew_files    ENABLE ROW LEVEL SECURITY;

-- ── helper: is the calling user a member of a crew? ──────────────
CREATE OR REPLACE FUNCTION public.is_crew_member(p_crew_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.crew_members
    WHERE crew_id = p_crew_id AND user_id = auth.uid()
  );
$$;

-- ── helper: is the calling user the crew owner? ──────────────────
CREATE OR REPLACE FUNCTION public.is_crew_owner(p_crew_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.crews
    WHERE id = p_crew_id AND owner_id = auth.uid()
  );
$$;

-- ── profiles ─────────────────────────────────────────────────────
DROP POLICY IF EXISTS "profiles: own row full access" ON public.profiles;
CREATE POLICY "profiles: own row full access"
  ON public.profiles FOR ALL
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "profiles: anyone can read" ON public.profiles;
CREATE POLICY "profiles: anyone can read"
  ON public.profiles FOR SELECT
  USING (true);

-- ── crews ────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "crews: public crews readable by all" ON public.crews;
CREATE POLICY "crews: public crews readable by all"
  ON public.crews FOR SELECT
  USING (is_public = true OR owner_id = auth.uid() OR is_crew_member(id));

DROP POLICY IF EXISTS "crews: members can read private crews" ON public.crews;
CREATE POLICY "crews: members can read private crews"
  ON public.crews FOR SELECT
  USING (owner_id = auth.uid() OR is_crew_member(id));

DROP POLICY IF EXISTS "crews: authenticated users can create" ON public.crews;
CREATE POLICY "crews: authenticated users can create"
  ON public.crews FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND owner_id = auth.uid());

DROP POLICY IF EXISTS "crews: owner can update" ON public.crews;
CREATE POLICY "crews: owner can update"
  ON public.crews FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS "crews: owner can delete" ON public.crews;
CREATE POLICY "crews: owner can delete"
  ON public.crews FOR DELETE
  USING (owner_id = auth.uid());

-- ── crew_members ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "crew_members: members can read" ON public.crew_members;
CREATE POLICY "crew_members: members can read"
  ON public.crew_members FOR SELECT
  USING (is_crew_member(crew_id));

DROP POLICY IF EXISTS "crew_members: owner manages members" ON public.crew_members;
CREATE POLICY "crew_members: owner manages members"
  ON public.crew_members FOR ALL
  USING (is_crew_owner(crew_id))
  WITH CHECK (is_crew_owner(crew_id));

-- ── join_requests ────────────────────────────────────────────────
DROP POLICY IF EXISTS "join_requests: user sees own requests" ON public.join_requests;
CREATE POLICY "join_requests: user sees own requests"
  ON public.join_requests FOR SELECT
  USING (user_id = auth.uid() OR is_crew_owner(crew_id));

DROP POLICY IF EXISTS "join_requests: authenticated users can request" ON public.join_requests;
CREATE POLICY "join_requests: authenticated users can request"
  ON public.join_requests FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL AND user_id = auth.uid());

DROP POLICY IF EXISTS "join_requests: owner can update status" ON public.join_requests;
CREATE POLICY "join_requests: owner can update status"
  ON public.join_requests FOR UPDATE
  USING (is_crew_owner(crew_id));

-- ── crew_messages ────────────────────────────────────────────────
DROP POLICY IF EXISTS "crew_messages: members can read" ON public.crew_messages;
CREATE POLICY "crew_messages: members can read"
  ON public.crew_messages FOR SELECT
  USING (is_crew_member(crew_id));

DROP POLICY IF EXISTS "crew_messages: members can post" ON public.crew_messages;
CREATE POLICY "crew_messages: members can post"
  ON public.crew_messages FOR INSERT
  WITH CHECK (is_crew_member(crew_id) AND user_id = auth.uid());

DROP POLICY IF EXISTS "crew_messages: author can delete own" ON public.crew_messages;
CREATE POLICY "crew_messages: author can delete own"
  ON public.crew_messages FOR DELETE
  USING (user_id = auth.uid());

-- ── crew_notes ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "crew_notes: members can read" ON public.crew_notes;
CREATE POLICY "crew_notes: members can read"
  ON public.crew_notes FOR SELECT
  USING (is_crew_member(crew_id));

DROP POLICY IF EXISTS "crew_notes: members can create" ON public.crew_notes;
CREATE POLICY "crew_notes: members can create"
  ON public.crew_notes FOR INSERT
  WITH CHECK (is_crew_member(crew_id) AND author_id = auth.uid());

DROP POLICY IF EXISTS "crew_notes: author or owner can update" ON public.crew_notes;
CREATE POLICY "crew_notes: author or owner can update"
  ON public.crew_notes FOR UPDATE
  USING (author_id = auth.uid() OR is_crew_owner(crew_id));

DROP POLICY IF EXISTS "crew_notes: author or owner can delete" ON public.crew_notes;
CREATE POLICY "crew_notes: author or owner can delete"
  ON public.crew_notes FOR DELETE
  USING (author_id = auth.uid() OR is_crew_owner(crew_id));

-- ── crew_links ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "crew_links: members can read" ON public.crew_links;
CREATE POLICY "crew_links: members can read"
  ON public.crew_links FOR SELECT
  USING (is_crew_member(crew_id));

DROP POLICY IF EXISTS "crew_links: members can add" ON public.crew_links;
CREATE POLICY "crew_links: members can add"
  ON public.crew_links FOR INSERT
  WITH CHECK (is_crew_member(crew_id) AND added_by = auth.uid());

DROP POLICY IF EXISTS "crew_links: adder or owner can delete" ON public.crew_links;
CREATE POLICY "crew_links: adder or owner can delete"
  ON public.crew_links FOR DELETE
  USING (added_by = auth.uid() OR is_crew_owner(crew_id));

-- ── crew_files ───────────────────────────────────────────────────
DROP POLICY IF EXISTS "crew_files: members can read" ON public.crew_files;
CREATE POLICY "crew_files: members can read"
  ON public.crew_files FOR SELECT
  USING (is_crew_member(crew_id));

DROP POLICY IF EXISTS "crew_files: members can upload" ON public.crew_files;
CREATE POLICY "crew_files: members can upload"
  ON public.crew_files FOR INSERT
  WITH CHECK (is_crew_member(crew_id) AND uploaded_by = auth.uid());

DROP POLICY IF EXISTS "crew_files: uploader or owner can delete" ON public.crew_files;
CREATE POLICY "crew_files: uploader or owner can delete"
  ON public.crew_files FOR DELETE
  USING (uploaded_by = auth.uid() OR is_crew_owner(crew_id));

-- ════════════════════════════════════════════════════════════════
-- Storage bucket and storage.objects policies are managed separately.
-- After this file, run crewup_official_site/supabase_storage_setup.sql.
-- Bucket name: crew-files  (private, 50 MB limit)
-- ════════════════════════════════════════════════════════════════
