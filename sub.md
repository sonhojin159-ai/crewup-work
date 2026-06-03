# [Context]
Crew Up 공식 사이트/앱은 `/workspace/MA/crewup_official_site` 아래에 있다.
핵심 파일은 `crewup_official_site/app.html`, 스키마는 `crewup_official_site/supabase_schema.sql`이다.

현재 실제 Supabase 연결 상태에서 사용자가 다음 문제를 보고했다.

1. 갑자기 멤버 관리 기능이 안 됨.
2. 업로드 권한 설정에서 멤버별 개인 토글은 동작함.
3. 하지만 한 번에 켜고 끄는 전체 허용 토글 버튼은 작동하지 않음.

직전 커밋은 `1d8f7be Wire crew join request approvals`이며, 이 커밋 이후 사용자 테스트에서 문제가 확인됐다.

현재 코드상 확인된 유력 원인:

- `app.html`의 `renderMembers(members)` real-mode 렌더링에서 멤버 행 우측 관리 버튼을 항상 disabled 상태로 생성한다.
  - 현재 버튼 aria-label도 `멤버 관리 메뉴는 준비 중이에요`로 되어 있다.
  - 그래서 기존 정적 UI의 row menu / 내보내기 / 권한 설정 안내가 real-mode 멤버 목록에서는 작동하지 않는다.

- `setupRealPermissionCard()`가 real-mode에서 `[data-all]` 전체 허용 체크박스를 전부 강제로 비활성화한다.
  - `cb.disabled = true`
  - 힌트도 “전체 허용 설정은 아직 DB 컬럼이 없어 사용할 수 없습니다…”라고 되어 있다.
  - 그래서 개인 토글만 DB 저장되고 전체 토글은 클릭 자체가 막혀 있다.

관련 현재 코드 위치:
- `app.html` around `renderMembers(members)`
- `app.html` around `setupRealPermissionCard()`
- `app.html` around permission card `refresh()` / `[data-all]` change listener
- `app.html` around `bindPermissionToggles()` 개인 권한 저장 로직

관련 테이블:
- `crew_members(crew_id, user_id, role, can_files, can_photos, can_videos, joined_at)`

## [New Task]
`crewup_official_site/app.html`에서 실제 Supabase 작업실의 멤버 관리와 전체 업로드 권한 토글을 다시 동작하게 수정한다.

### 1. 멤버 관리 버튼 복구
real-mode `renderMembers(members)`에서 멤버 행 우측 버튼을 disabled로만 렌더링하지 말고 관리 메뉴가 작동하게 한다.

필수 요구사항:
- 크루장 본인/owner 행은 안전하게 관리 불가 또는 제한 상태 유지.
- 일반 멤버 행에는 기존 디자인의 3-dot 관리 메뉴를 렌더링한다.
- 메뉴에는 최소 다음 액션이 있어야 한다.
  - 업로드 권한 설정: 멤버 관리 화면/권한 카드로 안내 또는 스크롤/토스트
  - 멤버 내보내기: 실제 DB에서 `crew_members` row 삭제
- `data-row-menu`, `row-menu`, `data-kick`, `data-grant` 등 기존 정적 로직과 충돌하지 않게 한다.
- 동적 렌더링 후에도 작동하도록 event delegation 방식 권장.
- 내보내기는 크루장 자신/owner를 삭제하지 않도록 방어한다.
- Supabase RLS 실패 시 성공처럼 보이면 안 된다.

멤버 내보내기 로직:
1. 대상 `crew_id`, `user_id` 확인.
2. `crew_members`에서 해당 row delete.
3. 성공 후 `loadMembers(crewId)` 재조회.
4. toast: “멤버를 내보냈어요”
5. 실패 시 버튼 복구, console.warn, toast: “멤버를 내보내지 못했어요”

### 2. 전체 업로드 권한 토글 실제 DB 연결
현재 `[data-all]` 토글은 real-mode에서 비활성화되어 있다. 사용자가 “한 번에 하는 토글”을 누르면 해당 권한 컬럼을 모든 일반 멤버에게 일괄 update해야 한다.

권한 매핑:
- `data-all="doc"` → `can_files`
- `data-all="photo"` → `can_photos`
- `data-all="video"` → `can_videos`

동작 방식:
1. real-mode에서도 `[data-all]` 체크박스를 disabled 하지 않는다.
2. 토글 change 시 active crew가 없으면 원복하고 안내한다.
3. owner를 제외한 일반 멤버 전체에 대해 해당 컬럼을 checked 값으로 update한다.
   - `.eq("crew_id", activeCrew.id)`
   - `.neq("role", "owner")` 또는 대상 user_id 목록 기반 update
4. 성공 후 `loadMembers(crewId)` 재조회하여 개인 토글 UI와 실제 DB 상태를 동기화한다.
5. 실패 시 체크 상태를 이전 값으로 되돌리고 console.warn + 실패 toast.

주의:
- 전체 토글은 별도 DB 컬럼을 새로 만들 필요 없다.
- 현재 목적은 “현재 멤버들의 해당 권한을 일괄 변경”이다.
- 신규 멤버 기본 권한 정책까지 저장하는 기능은 이번 범위가 아니다.
- service_role key 추가 금지. 기존 anon Supabase client + RLS 사용.

### 3. 개인 토글과 전체 토글 동기화
- 개인 토글이 하나씩 바뀐 뒤 전체 토글 체크 상태가 현재 멤버들의 상태를 반영하면 좋다.
  - 예: 모든 일반 멤버가 `can_files=true`면 doc 전체 토글 checked.
  - 일부라도 false면 unchecked.
- 최소한 전체 토글 성공 후에는 `loadMembers()`를 통해 UI가 정확히 갱신되어야 한다.
- `refresh()`가 real-mode에서 “전체 허용 설정은 아직 DB 컬럼이 없어 사용할 수 없습니다”라고 표시하는 문구는 제거/수정한다.
  - 예: “전체 토글은 현재 멤버들의 권한을 한 번에 변경합니다.”

### 4. 기존 참여신청 수락/거절 기능 유지
- 직전 작업의 `renderApplicants()`, `resolveRealApplicant()`, `loadApplicants()` 기능을 깨뜨리지 않는다.
- 수락 후 새 멤버가 추가되면 권한 카드에도 나타나야 한다.

### 5. 검증
필수 검증:
- inline script 추출 후 `node --check` 통과.
- `git diff --check` 통과.
- 로컬 브라우저에서 `crewup_official_site/app.html?workspace=1` 로딩 시 console/pageerror 없음.
- 가능한 경우 DOM/브라우저에서 다음 확인:
  - real-mode 멤버 행의 3-dot 관리 버튼이 disabled가 아님.
  - 일반 멤버 행 메뉴가 열린다.
  - 업로드 권한 설정 메뉴가 멤버 관리/권한 카드로 안내한다.
  - 전체 권한 토글 체크박스가 disabled가 아님.
  - 전체 토글 클릭 시 관련 개인 토글 UI가 같이 갱신된다.
- 변경 커밋.
- `sub_done.md` 갱신.

## [Completed]
- 크루 생성/owner insert 구현됨.
- 참여 신청 생성/표시 구현됨.
- 참여 신청 수락/거절 실제 Supabase update/upsert 구현됨. 커밋: `1d8f7be Wire crew join request approvals`
- 멤버별 개인 업로드 권한 토글은 실제 `crew_members.can_files/can_photos/can_videos` update로 동작한다고 사용자 확인.

## [Agent Report Template]
[에이전트 제출용 _done.md 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 구현 요약:
- 멤버 관리 버튼/메뉴 처리 방식:
- 멤버 내보내기 처리 방식:
- 전체 업로드 권한 토글 처리 방식:
- 개인 토글/전체 토글 동기화 방식:
- 기존 참여신청 기능 영향:
- 검증 결과:
- 커밋:
- 에러 및 특이사항:
