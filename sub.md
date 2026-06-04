# [Context]
Crew Up 공식 사이트/앱은 `/workspace/MA/crewup_official_site` 아래에 있다.
핵심 파일은 `crewup_official_site/index.html`, `crewup_official_site/app.html`, 런타임 Supabase config는 Netlify build가 생성하는 `config.js`다.

사용자가 전체 서버/연동이 불안정하다고 보고했다.
특히 모바일에서 크루가 보이다가 안 보이는 증상이 있고, PC에서 생성된 크루가 모바일에서 안정적으로 보여야 한다.

## [New Task]
PC~모바일 전체 코드/런타임 안정성 점검 및 긴급 안정화 패치.

핵심 목표:
- 모바일/PC 모두 공개 크루 목록이 안정적으로 렌더링되어야 한다.
- 모바일/PC 모두 Supabase client 초기화가 동일하게 동작해야 한다.
- PC에서 생성된 public crew가 모바일 랜딩 크루 목록에 보여야 한다.
- 로그인된 작업실에서는 PC/모바일 모두 같은 Supabase session + membership/owner query 기준으로 내 크루가 보여야 한다.

점검/패치 요구:
1. Supabase JS 로딩 안정화
   - 외부 CDN 의존으로 모바일 네트워크에서 간헐적으로 `window.supabase`가 없으면 크루 목록이 비어 보일 수 있다.
   - Supabase UMD bundle을 로컬 `assets/supabase.js`로 vendor하여 `index.html`, `app.html`이 로컬 파일을 사용하게 한다.
2. config.js 캐시 안정화
   - 랜딩 `index.html`의 config.js 로드에 cache-busting을 적용한다.
   - 앱 `app.html`의 fetch no-store는 유지한다.
3. 공개 크루 목록 query 안정화
   - `fetchPublicCrews()`에 transient network/query 실패 재시도를 추가한다.
   - 기존 fallback 순서(full select → no profile join → minimal select)는 유지한다.
4. 작업실 내 크루 query 안정화
   - membership 기반 query와 owner 기반 query에 재시도를 추가한다.
   - 기존 owner/membership merge, 모바일 크루 메뉴, owner membership repair는 유지한다.
5. 검증
   - `node --check`로 index/app inline script와 vendored Supabase JS 문법 확인.
   - `git diff --check` 통과.
   - 로컬 서버에서 PC/모바일 viewport 확인.
   - public landing `#crews`에서 카드 렌더링 확인.
   - app `app.html?workspace=1`에서 Supabase config/client 초기화와 이메일+비밀번호 로그인 폼 확인.
   - console/pageerror/requestfailed 없음.

## [Completed]
- Magic link 제거 및 이메일+비밀번호 로그인 전환 완료.
- 다중 크루 목록/모바일 크루 전환 구현 완료.
- public crew query fallback 구현 완료.
- 작업실 owner-created crew 보강 로직 구현 완료.
- 랜딩/작업실 Supabase config는 `window.CREWUP_CONFIG` + anon key만 사용한다. service_role/비밀키 금지.

## [Agent Report Template]
[에이전트 제출용 _done.md 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 불안정 원인 가설/확인:
- Supabase JS 로딩 안정화:
- config.js 캐시 안정화:
- public crew query 재시도:
- workspace my crews query 재시도:
- PC/모바일 검증 결과:
- 배포 결과:
- 에러 및 특이사항:
