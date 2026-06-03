-- Crew Up one-time repair: ensure every crew owner is also a crew member.
-- Run in Supabase SQL Editor if existing owner-created crews show as
-- "참여한 크루 없음" in the workspace.

INSERT INTO public.crew_members (crew_id, user_id, role, can_files, can_photos, can_videos)
SELECT c.id, c.owner_id, 'owner', true, true, true
FROM public.crews c
WHERE c.owner_id IS NOT NULL
ON CONFLICT (crew_id, user_id)
DO UPDATE SET role = 'owner';
