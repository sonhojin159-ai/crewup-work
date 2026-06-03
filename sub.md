# [Context]
Crew Up 공식 사이트는 `/workspace/MA/crewup_official_site`에 있으며 Netlify + Supabase 실제 배포가 빌드 성공한 상태다.
사용자가 실제 사이트에서 테스트한 결과, 빌드는 되지만 핵심 앱 동작에 문제가 있다.

사용자가 확인한 증상:
- 크루를 만들어도 랜딩페이지의 공개 크루 목록에 새 크루가 나오지 않음.
- 대시보드/멤버 화면에 실제 DB 상태와 무관한 멤버/활동/자료 같은 더미 데이터가 계속 보임.
- 로그인/작업실 접근 후 다시 랜딩페이지로 돌아가는 흐름이 불편하거나 잘못 동작함.

Hermes가 코드상 확인한 유력 원인:
- `app.html`의 크루 생성 플로우(`#flow-enter`)는 현재 UI만 바꾸고 `crews`, `crew_members`에 insert하지 않는다.
- `index.html`의 `modal-create`도 성공 UI만 보여주고 Supabase에 실제 크루를 만들지 않는다.
- `app.html` Supabase auth handler가 `?workspace=1`이 없으면 세션이 있어도 `index.html`로 강제 redirect한다.
- `app.html`에는 초기 시안용 정적 멤버/최근활동/파일/노트/링크 데이터가 많이 남아 있어 실제 신규 크루/빈 크루 상태에서도 멤버가 있는 것처럼 보인다.

주요 파일:
- `crewup_official_site/index.html`: 방문자용 랜딩/공개 크루 목록/참여 신청/랜딩의 크루 만들기 모달
- `crewup_official_site/app.html`: 로그인 후 크루 작업실 앱/크루 생성 플로우/대시보드
- `crewup_official_site/supabase_schema.sql`: 현재 `crews`, `crew_members`, `join_requests` 등 RLS 포함

주의:
- 이번 작업은 신규 대형 기능이 아니라 실제 Supabase 연동 후 드러난 핵심 버그 수정이다.
- `crewup_official_site/config.js`는 gitignored 실제 키 파일이므로 수정/커밋하지 않는다.
- service_role key, DB password 등 비공개 키를 프론트엔드에 넣지 않는다.
- 더미 UI를 완전히 디자인 재작성하지 말고, 실제 데이터가 없을 때는 빈 상태가 보이도록 최소 패치한다.

## [New Task]
이번 작업은 아래 문제만 집중 수정한다.

### 1. `app.html` 크루 생성 플로우를 실제 Supabase insert로 연결

대상 코드 근처:
- `#flow-enter` click handler: 현재 대략 `app.html` 2378행 부근
- Supabase auth/data loader IIFE: 현재 대략 `app.html` 2708행 이후

수정 요구:
1. Supabase가 준비되어 있고 로그인 사용자가 있을 때 `#flow-enter` 클릭 시 실제 DB에 저장한다.
   - `crews` insert:
     - `name`: `flow.data.name`
     - `description`: `#flow-purpose` 값. 비어 있으면 null 또는 빈 문자열 허용
     - `category`: `flow.data.cat`
     - `owner_id`: 현재 로그인 사용자 id
     - `is_public`: true 기본값 유지 또는 명시 true
   - insert 후 반환된 `crew.id`로 `crew_members` insert:
     - `crew_id`: 생성된 crew id
     - `user_id`: 현재 로그인 사용자 id
     - `role`: `owner`
2. insert 실패 시 성공 UI/토스트를 띄우지 말고 사용자에게 실패를 알려야 한다.
   - console.warn에 Supabase error message 남기기
   - 버튼은 다시 활성화
3. insert 성공 후:
   - `window.__activeCrew` 갱신
   - `.cs-name`, `.ab-name`, crew switcher 표시를 새 크루명으로 갱신
   - `body.dataset.crewstate = "new"` 또는 실제 신규 크루 빈 상태에 맞는 상태로 설정
   - `showView("dash")`
   - `toast("크루가 만들어졌어요")` 등 성공 표시
4. Supabase가 없는 로컬/오프라인 확인 흐름은 기존처럼 UI-only fallback을 유지해도 된다.
5. 같은 사용자가 만든 크루가 즉시 공개 목록에 보이도록 `crews.is_public`이 true인지 확인한다.

### 2. `index.html` 랜딩의 `크루 만들기` 모달도 실제 생성 또는 명확한 작업실 이동으로 정리

대상 코드 근처:
- `index.html`의 `.modal form` submit handler: 현재 대략 1623행 부근
- Supabase public crew list loader: 현재 대략 1858행 이후

수정 요구:
1. 로그인된 사용자(`currentUser`)가 있고 Supabase가 준비된 경우, 랜딩의 `modal-create` submit도 실제 `crews` + `crew_members(owner)`를 insert한다.
2. 로그인하지 않은 사용자가 랜딩에서 크루 만들기를 제출하면 가짜 성공 UI를 띄우지 말고 로그인/작업실로 보내야 한다.
   - 예: “크루 만들기는 로그인이 필요해요. 로그인 후 작업실에서 이어가세요.”
   - 이동 URL은 `app.html?workspace=1` 권장
3. 생성 성공 후에는 `app.html?workspace=1`로 이동할 수 있게 하거나, 현재 페이지에서 public crew list를 다시 불러와 새 크루가 보이게 한다.
   - 최소 요구: 생성된 크루가 DB에 저장되고, 새로고침 후 랜딩 공개 크루 목록에 나온다.
4. 기존 참여 신청(`join`) submit intercept와 충돌하지 않게 한다.

### 3. 작업실 로그인/redirect 흐름 수정

현재 문제 코드:
- `app.html` Supabase auth handler에서 `isWorkspaceRequest`가 false면 세션이 있어도 `window.location.replace("index.html")` 실행.
- Magic Link redirect URL도 현재 `index.html`로 가도록 되어 있음.

수정 요구:
1. 사용자가 `app.html`을 직접 열거나 Magic Link 후 작업실에 들어오면 랜딩으로 강제 이동하지 않게 한다.
2. Magic Link `emailRedirectTo`는 `location.origin + location.pathname` 또는 명확히 `app.html?workspace=1`이 되도록 조정한다.
3. `?workspace=1`이 없다는 이유만으로 로그인 사용자를 랜딩으로 돌려보내지 않는다.
4. 랜딩에서 로그인/시작하기/내 크루 CTA는 계속 `app.html?workspace=1`로 연결되도록 유지한다.

### 4. 대시보드/멤버/활동의 더미 데이터 노출 최소화

대상:
- `app.html` 대시보드 최근 활동, 멤버 카드, 멤버 목록, 파일/노트/링크 active 샘플

수정 요구:
1. 실제 Supabase 연결 상태에서는 DB 데이터가 없으면 시안용 더미 멤버/활동/파일/노트/링크가 보이지 않아야 한다.
2. 신규 생성 직후 owner 1명만 있는 크루라면:
   - 멤버 수는 1명으로 표시
   - 멤버 목록에는 크루장 본인 1명만 표시
   - “멤버”, “신청자”, “템플릿.fig”, “첫_자료.pdf”, 가짜 활동 등은 숨김 또는 빈 상태로 표시
3. 가능하면 `loadCrewData(crew.id)` 후 실제 `crew_members`를 select해서 `#member-list`, `[data-member-count]`를 갱신한다.
   - FK alias가 필요하면 현재 스키마 기준으로 맞춰서 사용
   - 어렵다면 최소한 신규/빈 상태에서 더미 멤버 행들을 숨기고 owner 1명만 보이게 한다.
4. 참여 신청(`join_requests`)은 크루 owner 화면에서 pending 신청 수와 목록에 반영되면 좋다.
   - MVP 최소: pending이 없으면 “대기 중인 신청이 없어요”만 보이고 카운트 0.
5. static prototype의 시각적 구조는 유지하되, “실제 앱 상태처럼 보이는 더미 데이터”를 실제 연결 상태에서 노출하지 않는다.

### 5. 검증

가능한 검증:
1. 정적 문법 검사:
   - HTML 안 JS를 추출하거나 가능한 방식으로 `node --check` 수행
   - 최소한 브라우저 console syntax error가 없어야 함
2. config 없는 로컬 상태에서도 페이지가 깨지지 않아야 함.
3. 실제 Supabase config가 있는 경우 수동 테스트 시나리오를 보고서에 적어야 함:
   - 로그인 후 `app.html?workspace=1` 진입
   - 크루 생성
   - Supabase `crews` row 생성 확인
   - Supabase `crew_members` owner row 생성 확인
   - 랜딩 `index.html#crews` 새로고침 후 공개 크루 목록에 새 크루 표시
   - 신규 크루 대시보드에서 멤버 1명/빈 활동 상태 확인

## [Completed]
완료된 기존 작업:
- Crew Up 공식 사이트 `/workspace/MA/crewup_official_site` 생성
- `index.html`: 방문자 랜딩/공개 크루 목록/참여 신청 UI
- `app.html`: Magic Link/Auth/session/data loader 초안
- `config.example.js`, `.gitignore`의 `crewup_official_site/config.js` 제외
- `supabase_schema.sql` 생성 및 RLS policy 반복 실행 가능 구조
- Netlify 빌드 설정 수정 완료:
  - `base = "crewup_official_site"`
  - `publish = "."`
  - build command가 `config.js`를 base directory에 생성
- 배포 빌드 성공 확인됨
- 실서버 테스트에서 이번 신규 버그들이 발견됨

## [Agent Report Template]
[에이전트 제출용 `_done.md` 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 수정 요약:
  - app.html 크루 생성 DB insert 처리:
  - index.html 랜딩 크루 생성 처리:
  - 작업실 redirect/Magic Link redirect 처리:
  - 더미 멤버/대시보드 데이터 노출 정리:
- 검증 결과:
  - JS 문법/console error 확인:
  - config 없는 로컬 fallback 확인:
  - Supabase 실제 수동 테스트 여부 및 결과:
  - 랜딩 공개 크루 목록 표시 확인:
  - 신규 크루 대시보드 빈 상태 확인:
- 에러 및 특이사항:
