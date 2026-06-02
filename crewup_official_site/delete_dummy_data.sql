-- Crew Up dummy/test data cleanup
-- Supabase SQL Editor에서 실행하세요.
-- 목적: 초기 연결 테스트용으로 만든 공개 크루와 그 하위 데이터를 삭제합니다.

begin;

with target_crews as (
  select id
  from public.crews
  where name in (
    'AI 숏폼 제작 크루',
    '숏폼 제작 크루',
    '원페이지 빌더스',
    '사이드 AI',
    '프롬프트 연구회',
    '메이커 클럽',
    '콘텐츠 루틴'
  )
)
delete from public.join_requests
where crew_id in (select id from target_crews);

with target_crews as (
  select id
  from public.crews
  where name in (
    'AI 숏폼 제작 크루',
    '숏폼 제작 크루',
    '원페이지 빌더스',
    '사이드 AI',
    '프롬프트 연구회',
    '메이커 클럽',
    '콘텐츠 루틴'
  )
)
delete from public.crew_messages
where crew_id in (select id from target_crews);

with target_crews as (
  select id
  from public.crews
  where name in (
    'AI 숏폼 제작 크루',
    '숏폼 제작 크루',
    '원페이지 빌더스',
    '사이드 AI',
    '프롬프트 연구회',
    '메이커 클럽',
    '콘텐츠 루틴'
  )
)
delete from public.crew_notes
where crew_id in (select id from target_crews);

with target_crews as (
  select id
  from public.crews
  where name in (
    'AI 숏폼 제작 크루',
    '숏폼 제작 크루',
    '원페이지 빌더스',
    '사이드 AI',
    '프롬프트 연구회',
    '메이커 클럽',
    '콘텐츠 루틴'
  )
)
delete from public.crew_links
where crew_id in (select id from target_crews);

with target_crews as (
  select id
  from public.crews
  where name in (
    'AI 숏폼 제작 크루',
    '숏폼 제작 크루',
    '원페이지 빌더스',
    '사이드 AI',
    '프롬프트 연구회',
    '메이커 클럽',
    '콘텐츠 루틴'
  )
)
delete from public.crew_files
where crew_id in (select id from target_crews);

with target_crews as (
  select id
  from public.crews
  where name in (
    'AI 숏폼 제작 크루',
    '숏폼 제작 크루',
    '원페이지 빌더스',
    '사이드 AI',
    '프롬프트 연구회',
    '메이커 클럽',
    '콘텐츠 루틴'
  )
)
delete from public.crew_members
where crew_id in (select id from target_crews);

delete from public.crews
where name in (
  'AI 숏폼 제작 크루',
  '숏폼 제작 크루',
  '원페이지 빌더스',
  '사이드 AI',
  '프롬프트 연구회',
  '메이커 클럽',
  '콘텐츠 루틴'
);

commit;
