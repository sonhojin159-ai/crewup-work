# [Context]
Crew Up 공식 사이트/앱은 `/workspace/MA/crewup_official_site` 아래에 있다.
핵심 파일은 `crewup_official_site/app.html`, `crewup_official_site/index.html`, 스키마는 `crewup_official_site/supabase_schema.sql`이다.

현재 실제 Supabase 연결 상태에서 사용자가 다음 문제를 보고했다.

1. 갑자기 멤버 관리 기능이 안 됨.
2. 업로드 권한 설정에서 멤버별 개인 토글은 동작함.
3. 하지만 한 번에 켜고 끄는 전체 허용 토글 버튼은 작동하지 않음.
4. 생각해보니 크루장이 자기 크루 포트폴리오/상세 보기 내용을 편집하는 곳이 없음.

직전 관련 커밋:
- `1d8f7be Wire crew join request approvals`
- `3b63ea4 docs: instruct Codex to restore member management`

현재 코드상 확인된 유력 원인:

- `app.html`의 `renderMembers(members)` real-mode 렌더링에서 멤버 행 우측 관리 버튼을 항상 disabled 상태로 생성한다.
  - 현재 버튼 aria-label도 `멤버 관리 메뉴는 준비 중이에요`로 되어 있다.
  - 그래서 기존 정적 UI의 row menu / 내보내기 / 권한 설정 안내가 real-mode 멤버 목록에서는 작동하지 않는다.

- `setupRealPermissionCard()`가 real-mode에서 `[data-all]` 전체 허용 체크박스를 전부 강제로 비활성화한다.
  - `cb.disabled = true`
  - 힌트도 “전체 허용 설정은 아직 DB 컬럼이 없어 사용할 수 없습니다…”라고 되어 있다.
  - 그래서 개인 토글만 DB 저장되고 전체 토글은 클릭 자체가 막혀 있다.

- 크루 상세 보기/포트폴리오는 `index.html`에 `#modal-folio`로 표시 UI가 있고, 카드의 `data-msg`, `data-style`, `data-tags`를 읽어 hydrate한다.
  - 하지만 `app.html` 크루 설정에는 포트폴리오 편집/저장 UI가 없다.
  - 현재 `crews` 테이블은 `name`, `description`, `category`, `is_public`, `owner_id`만 있다.
  - 포트폴리오용 한 줄 메시지, 진행 스타일, 태그, 소개 영상/대표 이미지 정보를 저장할 DB 필드가 없다.

관련 현재 코드 위치:
- `app.html` around `renderMembers(members)`
- `app.html` around `setupRealPermissionCard()`
- `app.html` around permission card `refresh()` / `[data-all]` change listener
- `app.html` settings view around `data-view="settings"`
- `index.html` around `#modal-folio`, `hydrate("folio")`, public crew list loader/render
- `supabase_schema.sql` around `CREATE TABLE public.crews`

관련 테이블:
- `crews(id, name, description, category, is_public, owner_id, created_at)`
- `crew_members(crew_id, user_id, role, can_files, can_photos, can_videos, joined_at)`

## [New Task]
`crewup_official_site/app.html`, `index.html`, `supabase_schema.sql`에서 실제 Supabase 작업실의 멤버 관리/전체 권한 토글을 복구하고, 크루장용 포트폴리오 편집 기능을 추가한다.

이번 작업은 기존 기능을 깨지지 않게 하는 패치다. 대규모 재설계 금지.

---

## 1. 멤버 관리 버튼 복구
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

---

## 2. 전체 업로드 권한 토글 실제 DB 연결
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

개인 토글과 전체 토글 동기화:
- 모든 일반 멤버가 `can_files=true`면 doc 전체 토글 checked.
- 일부라도 false면 unchecked.
- photo/video도 동일.
- 멤버가 0명일 때 전체 토글 상태가 이상하게 보이지 않게 처리한다.
- `refresh()`가 real-mode에서 “전체 허용 설정은 아직 DB 컬럼이 없어 사용할 수 없습니다”라고 표시하는 문구는 제거/수정한다.
  - 예: “전체 토글은 현재 멤버들의 권한을 한 번에 변경합니다.”

---

## 3. 크루장 포트폴리오 편집 기능 추가
크루장이 자신의 크루 상세 보기/포트폴리오 내용을 작업실에서 편집할 수 있게 한다.

### 3-1. DB 스키마 확장
`supabase_schema.sql`에 반복 실행 가능한 ALTER 문을 추가한다.

권장 컬럼:
- `portfolio_message text` — 한 줄 메시지
- `portfolio_style text` — 진행 스타일/소개 문장
- `portfolio_tags text[]` 또는 `jsonb` — 관심 분야/태그 목록
- `portfolio_video_url text` — MVP에서는 소개 영상 URL 또는 storage signed/public URL용 문자열
- `portfolio_image_urls jsonb` — 대표 이미지 URL 최대 3개 배열
- 필요 시 `updated_at timestamptz`는 나중 범위. 이번 작업에서 꼭 필요하지 않으면 생략 가능.

주의:
- 기존 운영 DB에도 적용 가능하도록 `ALTER TABLE public.crews ADD COLUMN IF NOT EXISTS ...` 형식 사용.
- `crews: owner can update` RLS가 이미 있으므로 새 컬럼도 owner update 대상이 된다.
- service_role key 금지.

### 3-2. app.html 설정 화면에 “크루 포트폴리오” 편집 카드 추가
`data-view="settings"` 안에 기본 정보 아래 또는 공개/모집 위에 새 set-card를 추가한다.

필드 요구사항:
- 한 줄 메시지
  - 예 placeholder: “잘 만든 한 편보다, 매주 한 편씩 끝내는 리듬을 같이 만들고 싶어요.”
- 진행 스타일/크루 소개
  - 예 placeholder: “매주 주제를 정해 각자 작업물을 만들고 금요일에 서로 피드백합니다.”
- 관심 분야/태그
  - 쉼표 구분 input으로 충분. 예: `꾸준함, 영상편집, 자동화`
- 소개 영상 URL
  - MVP에서는 URL 입력으로 처리한다. 직접 파일 업로드는 이번 범위에서 무리하면 제외 가능.
  - 향후 Storage 업로드로 확장 가능하게 id/name 명확히 지정.
- 대표 이미지 URL 1~3개
  - MVP에서는 URL 입력 3칸으로 처리한다.
  - 빈 값은 저장 시 제외.
- 저장 버튼
  - “포트폴리오 저장”

UX 요구사항:
- 현재 크루장만 저장 가능해야 한다. owner가 아니면 버튼 비활성화 또는 저장 시 RLS 실패 안내.
- 저장 성공 시 toast: “크루 포트폴리오를 저장했어요”
- 실패 시 성공처럼 보이면 안 됨. console.warn + toast.
- 저장 후 active crew 상태와 화면 표시를 갱신한다.

### 3-3. app.html 데이터 로드/저장 연결
- `loadCrewData()` / `applyCrewShell()`에서 active crew select에 새 포트폴리오 컬럼을 포함한다.
- 현재 active crew 정보를 설정 폼에 채운다.
- 저장 클릭 시 `sb.from("crews").update({...}).eq("id", activeCrew.id)`로 저장한다.
- 저장 후 `window.__activeCrew`에도 최신 값을 반영한다.
- 기존 기본 정보 저장 버튼이 데모 toast만 띄우는 문제도 가능하면 함께 정리한다.
  - 최소한 크루 이름/카테고리/description은 실제 DB update 되게 한다.
  - 단, 범위가 커지면 포트폴리오 저장 버튼만 우선 실제 연결해도 된다.

### 3-4. index.html 공개 크루 목록/상세 보기 반영
공개 크루 목록에서 Supabase `crews` select 시 새 포트폴리오 컬럼도 가져온다.

- public crew card의 `data-msg`, `data-style`, `data-tags`에 DB 값을 넣는다.
- `#modal-folio` hydrate 시:
  - `portfolio_message` → 한 줄 메시지
  - `portfolio_style` → 진행 스타일
  - `portfolio_tags` → 태그 렌더링
  - `portfolio_video_url` 있으면 소개 영상 영역에 링크/iframe/video 중 안전한 방식으로 표시
  - `portfolio_image_urls` 있으면 대표 작업 1~3개를 이미지로 표시
- 값이 없으면 기존 fallback 문구/placeholder 유지.
- 사용자가 원하지 않는 fake hardcoded real content를 새로 만들지 않는다.

### 3-5. 포트폴리오 미디어 범위
이번 MVP에서는 URL 입력 방식으로 충분하다.
- 영상/이미지 직접 업로드까지 넣으면 복잡해질 수 있으므로, 이미 구현된 공유함 업로드와 충돌시키지 말 것.
- 만약 직접 업로드를 구현한다면 Storage/RLS/파일 제한 검증까지 반드시 포함해야 한다. 시간이 부족하면 URL 방식으로 완료한다.

---

## 4. 기존 기능 유지
- 기존 참여신청 수락/거절 기능 유지.
- 기존 공유함 업로드/미리보기 기능 유지.
- 기존 멤버별 개인 권한 토글 유지.
- 랜딩 공개 크루 목록이 깨지지 않아야 한다.
- config.js에 비밀키 추가 금지.

---

## 5. 검증
필수 검증:
- inline script 추출 후 `node --check` 통과.
- `git diff --check` 통과.
- 로컬 브라우저에서 `crewup_official_site/app.html?workspace=1` 로딩 시 console/pageerror 없음.
- 로컬 브라우저에서 `crewup_official_site/index.html#crews` 로딩 시 console/pageerror 없음.
- 가능한 경우 DOM/브라우저에서 다음 확인:
  - real-mode 멤버 행의 3-dot 관리 버튼이 disabled가 아님.
  - 일반 멤버 행 메뉴가 열린다.
  - 업로드 권한 설정 메뉴가 멤버 관리/권한 카드로 안내한다.
  - 전체 권한 토글 체크박스가 disabled가 아님.
  - 전체 토글 클릭 시 관련 개인 토글 UI가 같이 갱신된다.
  - 설정 화면에 “크루 포트폴리오” 편집 카드가 보인다.
  - 포트폴리오 저장 버튼이 존재한다.
  - 공개 크루 상세 보기 모달이 DB 포트폴리오 값을 사용할 수 있게 연결되어 있다.
- 변경 커밋.
- `sub_done.md` 갱신.

## [Completed]
- 크루 생성/owner insert 구현됨.
- 참여 신청 생성/표시 구현됨.
- 참여 신청 수락/거절 실제 Supabase update/upsert 구현됨. 커밋: `1d8f7be Wire crew join request approvals`
- 공유함 업로드/미리보기 구현됨.
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
- 포트폴리오 DB 스키마 변경:
- 포트폴리오 편집 UI 위치/필드:
- 포트폴리오 저장 처리 방식:
- 공개 크루 상세 보기 반영 방식:
- 기존 참여신청/공유함 기능 영향:
- 검증 결과:
- 커밋:
- 에러 및 특이사항:
