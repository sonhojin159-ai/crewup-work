# [Context]
Crew Up 공식 사이트는 `/workspace/MA/crewup_official_site`에 있으며, 현재 Supabase MVP 연동 코드/문서/검수까지 완료된 상태다.

현재 단계는 실제 Supabase 프로젝트 URL/anon key를 넣어 실서버 테스트를 하기 직전이다.
Anti-Gravity 검수 결과 MVP 기준 승인 가능하며 Critical/High 보안 이슈는 없었지만, 실연동 전에 빠르게 반영하면 좋은 최소 보안 보강 항목이 남아 있다.

주요 파일:
- `crewup_official_site/index.html`: 방문자용 랜딩/공개 크루 목록/참여 신청
- `crewup_official_site/app.html`: 로그인 후 크루 작업실 앱
- `crewup_official_site/supabase_schema.sql`: Supabase DB/RLS 스키마
- `crewup_official_site/SUPABASE_SETUP.md`: Supabase 설정 가이드
- `crewup_official_site/config.example.js`: Supabase config 템플릿

주의:
- 이번 작업은 신규 구현이 아니라 실연동 전 최소 보안/문서 보강 패치다.
- `crewup_official_site/config.js`는 실제 Supabase URL/anon key를 넣는 로컬 비공개 파일이며, 이번 작업에서 생성하지 않는다.
- service_role key, DB password 등 비공개 키를 프론트엔드 파일에 넣지 않는다.

## [New Task]
이번 작업은 아래 항목만 수정한다.

1. `index.html` 공개 크루 initial 출력 escape 처리
   - 공개 크루 카드 렌더링에서 크루명 첫 글자 등으로 만든 `initial` 값이 HTML 문자열에 직접 합쳐지는 부분을 확인한다.
   - `initial`도 다른 사용자 입력/DB 값과 동일하게 `escHtml(initial)`로 출력되도록 수정한다.
   - 목적: 크루 이름에서 파생된 값이라도 HTML 삽입 가능성을 막기 위함.

2. `supabase_schema.sql` helper function search_path 보강
   - 아래 helper/function 정의에 `SET search_path = public`을 추가한다.
     - `public.is_crew_member`
     - `public.is_crew_owner`
   - 가능하면 신규 유저 프로필 생성 함수인 `public.handle_new_user`에도 `SET search_path = public`을 추가한다.
   - 기존 반복 실행 가능성을 해치지 말고, 이미 추가된 `DROP POLICY IF EXISTS` 구조를 유지한다.
   - 목적: `SECURITY DEFINER` 함수의 search_path 관련 보안 리스크를 줄이기 위함.

3. `SUPABASE_SETUP.md` Storage object RLS/policy 안내 보강
   - 현재 문서에 Storage bucket 생성 안내는 있으나 `storage.objects` RLS/policy 안내가 부족하다.
   - 아래 내용을 문서에 추가한다.
     - bucket name: `crew-files`
     - Public bucket: OFF
     - 업로드/조회/삭제 권한은 공개 bucket이 아니라 Supabase Storage policy로 제어해야 함
     - MVP 단계에서는 Dashboard에서 `crew-files` bucket을 만든 뒤, 실제 파일 업로드 기능을 연결하기 전 Storage policy를 별도로 점검해야 함
   - 이번 패치에서 파일 업로드 기능 자체를 새로 구현하지 않는다. 문서 보강만 한다.

4. 변경 후 최소 검증
   - 가능하면 아래 검증을 수행한다.
     - `crewup_official_site/index.html` 로딩 시 console error 없음
     - `crewup_official_site/app.html` config 없는 오프라인 확인용 흐름 유지
     - SQL 파일에서 helper function 문법상 명백한 오류가 없는지 확인
   - 실제 Supabase URL/anon key는 아직 없으므로 Magic Link 실서버 테스트는 하지 않아도 된다.

## [Completed]
Claude Code가 완료한 것으로 보고된 내용:
- `Crew App.html`을 `app.html`로 전환
- `index.html` 로그인/시작하기/작업실 이동 링크를 `app.html`로 연결
- `config.example.js`, `.gitignore`의 `crewup_official_site/config.js` 추가
- `supabase_schema.sql` 생성
- `SUPABASE_SETUP.md` 생성
- `index.html` 공개 크루 목록/참여 신청 Supabase 연동 초안 추가
- `app.html` Magic Link/Auth/session/data loader 초안 추가

이전 Codex 패치 완료 내용:
- `index.html` Supabase config 로딩 추가
- 공개 크루 목록 query 보강 및 FK alias 적용: `profiles!crews_owner_id_fkey(display_name)`
- query 실패 시 정적 카드 fallback 유지 및 `console.warn` 추가
- 참여 신청 시 `join_requests`에 `crew_id`, `user_id`, `message` 저장
- 중복 신청 `23505` 분기 처리
- 기존 성공 UI와 DB insert 결과 UI 충돌 완화
- `app.html` Magic Link 로그인 유지
- config 없는 상태에서는 확인용 입장 흐름 유지
- config 있는 상태에서는 확인용 버튼 숨김
- 회원가입 닉네임을 OTP `options.data`에 전달
- `supabase_schema.sql` RLS policy 앞에 `DROP POLICY IF EXISTS` 추가
- `.gitignore`에 `crewup_official_site/config.js` 제외 처리

Hermes 로컬 검증 완료:
- `http://127.0.0.1:4177/index.html?verify=codex` 로딩 정상, console error 없음
- `http://127.0.0.1:4177/app.html?verify=codex` 로딩 정상, console error 없음
- 이메일 입력 → 확인용 입장 → 작업실 진입 정상
- inline JS `node --check` 문법 검사 통과

Anti-Gravity 검수 완료:
- 보고서: `/workspace/MA/test_done.md`
- MVP 기준 승인 가능
- Critical/High 보안 이슈 없음
- 실제 Supabase 프로젝트 테스트는 아직 미수행
- 남은 개선 항목 중 이번 작업에서는 실연동 전 최소 보강만 처리한다.

## [Agent Report Template]
[에이전트 제출용 `_done.md` 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 수정 요약:
  - initial escape 처리 여부:
  - helper function `SET search_path = public` 처리 여부:
  - Storage RLS/policy 문서 보강 여부:
- 검증 결과:
  - index.html console error:
  - app.html config 없는 오프라인 확인 흐름:
  - SQL 문법/구조 확인:
  - Supabase 실제 연결 테스트 여부: (이번 단계에서는 보통 미수행)
- 에러 및 특이사항:
