# [Context]
Crew Up / CrewUp AI 공식 사이트와 작업실 앱은 `/workspace/MA/crewup_official_site` 안의 정적 HTML/JS와 Supabase DB를 사용한다.
현재 구조상 크루는 `crews.id` 기준으로 독립되어야 하고, 가입 신청은 `join_requests.crew_id` 하나에만 저장되어야 한다. 파일/채팅/노트도 `crew_id` 기준으로 분리된다.

사용자 실사용 제보:
- 한 사람이 여러 크루를 만들었을 때 크루들은 독립적으로 존재해야 한다.
- 그런데 다른 아이디로 특정 크루에 가입 신청을 했더니, 크루장 계정의 여러 크루에 동시에 멤버 신청이 온 것처럼 보였다.
- 즉 가입 신청이 특정 크루 하나에만 귀속되지 않거나, 관리 화면에서 신청 목록/배지가 현재 선택 크루와 독립적으로 섞여 보이는 버그가 의심된다.

관련 파일:
- `/workspace/MA/crewup_official_site/index.html`: 랜딩/공개 크루 목록/참여 신청 모달
- `/workspace/MA/crewup_official_site/app.html`: 작업실/크루 관리/참여 신청 수락 화면
- `/workspace/MA/crewup_official_site/supabase_schema.sql`: `crews`, `crew_members`, `join_requests` 및 RLS 정책

현재 확인된 코드 단서:
- `join_requests` 테이블은 `crew_id`, `user_id`, `status`를 가진다.
- `app.html`의 `loadApplicants(crewId)`는 `.eq("crew_id", crewId).eq("status", "pending")`로 필터링하므로 정상이라면 한 크루 신청만 보여야 한다.
- `index.html`의 참여 신청 저장은 `joinModal.dataset.crewId`를 사용해 `join_requests.insert({ crew_id: crewId, user_id: currentUser.id, ... })`한다.
- `index.html`에는 두 종류의 모달 오픈 로직이 섞여 있다.
  - 초기 정적 `[data-open]` 버튼용 `openModal(name, ctx)` / `hydrate(name, ctx)`
  - Supabase 동적 카드용 `__crewup_open_modal` 이벤트 / `reAttachCardListeners(grid)`
- 포트폴리오 상세 모달 안의 `참여 신청` 버튼은 `data-open="join"`인데, 이 버튼은 특정 카드 내부가 아니므로 `btn.closest("[data-crew]")`가 null이 될 수 있다. 이 경우 join modal이 이전에 열었던 `dataset.crewId`를 그대로 재사용하거나 빈 값이 되어 잘못된 크루에 신청될 수 있다.
- `index.html`에는 일반 demo submit handler와 Supabase join submit interceptor가 함께 존재한다. Supabase interceptor는 capture + `stopImmediatePropagation()`을 쓰지만, 모달 body를 성공 UI로 갈아끼우는 흐름이 섞여 있으므로 실제 저장 전후 상태를 명확히 확인해야 한다.

## [New Task]
Codex는 아래 버그를 직접 코드 수정하라.

1. 가입 신청은 반드시 사용자가 클릭한 정확한 `crew_id` 한 개에만 저장되도록 수정한다.
   - 랜딩의 공개 크루 카드에서 `참여 신청`을 누른 경우: 해당 카드의 `data-crew-id`만 사용.
   - `크루 상세보기` 모달에서 다시 `참여 신청`을 누른 경우: 상세보기 모달이 들고 있는 현재 `crew_id`를 join modal로 명시적으로 전달.
   - 카드/상세 모달 context가 없을 때 이전 `joinModal.dataset.crewId`를 재사용하지 말 것.
   - join modal을 열 때마다 textarea와 결과 상태를 안전하게 초기화하고, `dataset.crewId`를 명확히 세팅하거나 없으면 신청 저장을 막을 것.

2. 포트폴리오 상세 모달에 현재 크루 context를 저장하라.
   - 예: `#modal-folio.dataset.crewId`, crew name/category 등.
   - 상세 모달 안의 `data-open="join"` 버튼 클릭 시 이 context를 사용해 join modal을 hydrate하라.
   - 이벤트 핸들러가 정적/동적 카드 모두에서 같은 규칙으로 동작하도록 중복 로직을 정리하라.

3. 작업실 `app.html`의 참여 신청 목록이 현재 선택된 크루 신청만 보여주는지 방어적으로 보강하라.
   - `loadApplicants(crewId)` 응답을 렌더하기 전에도 `req.crew_id === crewId`인 항목만 통과시키는 클라이언트 방어 필터 추가.
   - 비동기 race 방지: 크루 A 신청 목록 요청 후 사용자가 크루 B로 전환했을 때 A 응답이 늦게 도착해 B 화면에 렌더되지 않도록, 응답 시점에 `window.__activeCrew.id === crewId`인지 확인.
   - 참여 신청 수락/거절 버튼의 `data-crew-id`도 active crew와 request crew가 맞는지 검증.

4. 사용자가 제보한 이전 UI 문제도 함께 확인하고 필요 시 수정한다.
   - 크루 관리 페이지에서 랜딩 페이지로 돌아가는 버튼이 없으면 추가.
   - 한 계정이 만든/가입한 여러 크루가 PC와 모바일 모두에서 전부 보이고 전환 가능해야 한다.
   - 모바일 메뉴도 PC와 같은 `window.__myCrews` 데이터를 사용해야 한다.
   - 랜딩 크루 카드의 `크루 상세보기` / `참여 신청` 버튼은 카드 하단에 고정되어, 설명 길이에 따라 위치가 흔들리지 않게 한다.
   - 모바일에서 공개 크루 목록이 안 뜨는 문제를 재현/수정한다. PC와 모바일 모두 같은 Supabase live data를 사용해야 하며, 하드코딩/가짜 데이터로 대체하지 말 것.

5. DB/RLS 구조는 큰 변경 전 반드시 확인한다.
   - `join_requests`는 `UNIQUE (crew_id, user_id)`라서 한 유저가 여러 크루에 각각 신청할 수는 있지만, 한 번의 신청이 여러 crew_id row로 복제되면 안 된다.
   - 코드 수정으로 해결 가능한 문제면 SQL 스키마를 변경하지 말 것.
   - 만약 실제 DB에 잘못 생성된 중복 신청 row가 있다면, 삭제/정리용 SQL은 별도 파일로 제안만 하고 자동 실행하지 말 것.

## [Completed]
- 기본 구조 확인 완료:
  - `crews`는 독립 row이며 `owner_id`만 같은 사람이 될 수 있다.
  - `crew_members`는 `(crew_id, user_id)` edge 테이블이다.
  - 파일/채팅/노트/신청은 모두 `crew_id`로 분리되어야 한다.
- 기존에 owner-created crews가 membership edge 누락으로 안 보이는 문제를 보완하는 코드가 들어가 있다:
  - `fetchMyCrewMemberships(userId)` + `fetchOwnedCrews(userId)` 병합
  - `repairMissingOwnerMemberships(userId, items)`

## [Verification Required]
수정 후 반드시 아래를 검증하고 `_done.md`에 결과를 적어라.

1. 문법/정적 검사
- `node --check` 또는 HTML inline script syntax 검사 방식으로 `index.html`, `app.html`의 JS 문법 오류 없음 확인.
- `git diff --check` 통과.

2. 브라우저 수동 검증
- PC viewport와 모바일 viewport 모두에서 확인.
- 공개 크루 목록이 실제 Supabase 데이터로 표시되는지 확인.
- 크루 A, 크루 B가 같은 owner 계정에 있을 때:
  - 신청자 계정으로 크루 A에만 참여 신청
  - owner 계정 작업실에서 크루 A 선택 시에만 신청이 보임
  - 크루 B 선택 시 신청이 보이지 않음
- 포트폴리오 상세보기 → 참여 신청 경로도 같은 방식으로 검증.
- 크루 전환을 빠르게 해도 이전 크루의 신청 목록이 현재 크루 화면에 늦게 렌더되지 않는지 확인.
- 모바일에서 내 크루 목록/공개 크루 목록/참여 신청 버튼 모두 동작 확인.

3. 배포/커밋
- 수정 파일을 git commit으로 보존.
- 가능하면 Netlify production deploy까지 진행.
- GitHub push가 인증 문제로 실패하면 `_done.md`에 명시.

## [Agent Report Template]
`sub_done.md`로 아래 형식 제출:

- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 확인한 근본 원인:
- 핵심 수정 요약:
- PC 검증 결과:
- 모바일 검증 결과:
- Supabase join_requests 동작 검증 결과:
- 배포 URL / 커밋 SHA:
- 에러 및 특이사항:
