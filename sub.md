# [Context]
Crew Up 공식 사이트/앱은 `/workspace/MA/crewup_official_site` 아래에 있다.
핵심 파일은 `crewup_official_site/app.html`, `crewup_official_site/index.html`, 스키마는 필요 시 `crewup_official_site/supabase_schema.sql`이다.

사용자가 Supabase 기본 이메일 발송 한도 때문에 magic link 방식이 너무 빨리 limit에 걸린다고 보고했고, magic link가 아닌 일반 로그인 방식으로 바꾸기를 요청했다.

현재 앱 인증 게이트는 `app.html` 내부에 있으며, 기존 구현은 `signInWithOtp()` 기반 magic link 로그인/가입이었다.

## [New Task]
이번 작업은 `crewup_official_site/app.html`의 인증 방식을 magic link에서 이메일+비밀번호 방식으로 전환하는 긴급 패치다.
대규모 리디자인 금지. Supabase service_role/비밀키 추가 금지.

필수 요구사항:
- 로그인 탭은 이메일 + 비밀번호 입력을 받아 `supabase.auth.signInWithPassword({ email, password })`를 사용한다.
- 회원가입 탭은 닉네임 + 이메일 + 비밀번호 입력을 받아 `supabase.auth.signUp({ email, password, options: { data: ... } })`를 사용한다.
- 일반 로그인 과정에서 `signInWithOtp()`/magic link/OTP 발송이 발생하면 안 된다.
- UI 문구에서 “로그인 링크 받기”, “가입 링크 받기”, “비밀번호 필요 없음” 같은 magic link 안내를 제거한다.
- 비밀번호는 최소 6자 입력을 요구한다.
- Supabase email confirmation이 켜져 있어 회원가입 후 session이 없을 경우, 가입 확인 메일을 확인한 뒤 이메일/비밀번호로 로그인하라는 안내를 보여준다.
- email confirmation을 끈 개발 환경에서는 회원가입 직후 session이 생기면 바로 로그인 상태로 진입할 수 있게 유지한다.
- 기존 Supabase session sync, `onAuthStateChange`, `getSession`, `loadCrewData()` 흐름은 깨지지 않아야 한다.
- 기존 다중 크루 목록/모바일 크루 전환/랜딩 복귀 버튼/랜딩 카드 정렬 패치는 건드리지 않는다.

검증:
- `app.html` inline script 추출 후 `node --check` 통과.
- `git diff --check` 통과.
- 로컬 정적 서버에서 `app.html?workspace=1`을 열었을 때 로그인 탭에 이메일+비밀번호가 보이고, 회원가입 탭에 닉네임+이메일+비밀번호가 보인다.
- DOM에 `signInWithOtp`와 `data-magic`이 남아있지 않다.
- console/pageerror 없음.
- 변경 커밋 생성.
- `sub_done.md` 갱신.

## [Completed]
- 크루 생성/owner insert 구현됨.
- 참여 신청 생성/표시/수락/거절 구현됨.
- 공유함 업로드/미리보기 구현됨.
- 멤버별 개인 업로드 권한 토글 및 멤버 관리 기능 구현됨.
- 포트폴리오 편집 기능 구현됨.
- 크루 관리/작업실에서 랜딩으로 돌아가는 버튼 완료:
  - 데스크톱 `.side-foot .home-link` → `index.html#home`
  - 모바일 `.appbar .home-link` → `index.html#home`
- 작업실 다중 크루 목록/전환 및 모바일 크루 메뉴 구현됨.
- 랜딩 크루 카드의 상세보기/참여신청 버튼 하단 고정 구현됨.
- 모바일 공개 크루 목록/작업실 크루 목록 fallback query 구현됨.

## [Agent Report Template]
[에이전트 제출용 _done.md 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 구현 요약:
- 로그인 처리 방식:
- 회원가입 처리 방식:
- magic link/OTP 제거 확인:
- 이메일 confirmation 켜진 환경 처리:
- 기존 크루 기능 영향:
- 검증 결과:
- 커밋:
- 에러 및 특이사항:
