# [Context]
Crew Up 공식 사이트/앱은 `/workspace/MA/crewup_official_site` 아래에 있다.
핵심 파일은 `crewup_official_site/app.html`, `crewup_official_site/index.html`, 스키마는 필요 시 `crewup_official_site/supabase_schema.sql`이다.

사용자가 실제 사용 중 다음 문제를 새로 보고했다.

1. 크루 관리/작업실 페이지에서 랜딩 페이지로 돌아가는 버튼이 없음.
   - 단, 직전 `sub_done.md` 기준으로 이 항목은 이미 완료된 것으로 보인다.
   - `app.html` 데스크톱 사이드바 `.side-foot .home-link`, 모바일 `.appbar .home-link`가 있다면 추가 작업하지 말 것.
2. 사용자가 여러 개의 크루에 가입했거나 여러 크루를 운영할 때, 작업실/크루 관리 페이지에서 내 크루 목록이 전부 보이지 않는다.
   - 현재 확인 위치: `app.html` `loadCrewData(userId)`가 `crew_members`를 조회하지만 `r.data[0]` 하나만 active crew로 사용한다.
   - `#crew-menu` 정적 마크업도 사실상 단일 `내 크루` 항목만 렌더링한다.
   - 모바일 `#appbar-crew`는 이름만 보이고 여러 크루 선택 UX가 부족해 보인다.
3. 랜딩 페이지의 크루 목록 카드에서 `크루 상세보기`와 `참여 신청` 버튼 위치가 카드마다 고정되어 있지 않다.
   - 현재 확인 위치: `index.html` `.crew-card`는 flex column이나 본문/리더 영역 길이에 따라 `.crew-actions`가 위아래로 흔들릴 수 있다.
   - 공개 크루 카드 렌더링 위치: `index.html` `buildCrewCard()` around public crew list.
4. 가장 큰 문제: 모바일에서 크루가 안 뜬다고 사용자가 보고했다.
   - PC 웹에서 구현한 Supabase 연동은 모바일 브라우저에서도 동일하게 보여야 한다.
   - 모바일에서 공개 크루 목록/내 크루 작업실이 안 보이는 원인을 반드시 찾아 수정해야 한다.
   - 단순 CSS만 보지 말고, 모바일 viewport에서 Supabase config/client 초기화, 공개 크루 목록 query, 작업실 내 크루 query, 모바일 appbar/crew switcher UX까지 확인할 것.

현재 알려진 구현 상태:
- 랜딩 `index.html`은 `config.js`를 동적 script로 로드한 뒤 Supabase client를 만든다.
- 공개 크루 목록은 `index.html`에서 `sb.from("crews")...eq("is_public", true)`로 조회한다.
- 작업실 `app.html`은 로그인 세션 후 `loadCrewData(session.user.id)`를 호출한다.
- 작업실 내 크루 조회는 `crew_members` 기준으로 join된 `crews(...)`를 가져온다.
- 이미 이전 작업에서 멤버 관리/권한 토글/포트폴리오 편집 관련 코드가 들어가 있을 수 있으므로, 이번 작업 범위와 무관한 대규모 재수정 금지.

## [New Task]
`crewup_official_site/app.html`와 `crewup_official_site/index.html`에서 아래 3가지를 집중 패치한다.

이번 작업은 기존 기능을 깨지지 않게 하는 긴급 UX/연동 패치다. 대규모 리디자인 금지. Supabase service_role/비밀키 추가 금지.

---

## 1. 작업실에서 사용자의 전체 크루 목록 표시/전환

### 목표
사용자가 여러 크루에 가입했거나 여러 크루의 크루장인 경우, 작업실/크루 관리 페이지에서 모든 내 크루를 볼 수 있고 원하는 크루로 전환할 수 있어야 한다.

### 필수 요구사항
- `loadCrewData(userId)`가 `r.data[0]` 하나만 쓰지 말고, 사용자의 모든 membership row를 정규화해 `window.__myCrews` 같은 배열로 보관한다.
- 각 항목에는 최소 다음 값이 있어야 한다.
  - `crew.id`, `name`, `description`, `category`, `owner_id`, `is_public`, 포트폴리오 컬럼들
  - 사용자의 해당 크루 role: `owner` 또는 `member`
- 기본 active crew는 기존처럼 첫 번째여도 되지만, 메뉴에서 다른 크루를 선택하면 active crew가 바뀌어야 한다.
- active crew 변경 시 반드시 다음 데이터를 해당 crew id로 다시 로드한다.
  - 멤버 목록
  - 참여 신청 목록
  - 파일/공유함
  - 채팅 메시지
  - 노트
  - 링크
  - 설정/포트폴리오 폼
- `window.__activeCrewRole`도 선택한 크루 role로 갱신한다.
- owner가 아닌 크루에서는 크루 설정/포트폴리오 저장 버튼이 비활성화되거나 RLS 실패 안내가 떠야 한다. 이미 구현돼 있다면 유지한다.
- no-crew 상태는 사용자가 어떤 크루에도 가입하지 않은 경우에만 보여야 한다.

### 데스크톱 UI
- `#crew-menu`에 사용자의 모든 크루를 렌더링한다.
- 각 항목은 크루 이름, 역할 뱃지/작은 텍스트(크루장/멤버), 카테고리 정도를 보여준다.
- 현재 active crew는 시각적으로 표시한다. 예: `.crew-menu-item.active`.
- `새 크루 만들기` 항목은 메뉴 하단에 계속 유지한다.

### 모바일 UI
- 모바일 `#appbar-crew`를 눌러도 내 크루 목록을 볼 수 있어야 한다.
- 구현은 둘 중 하나로 충분하다.
  1. 기존 `#crew-menu`를 모바일에서도 appbar 아래/오버레이로 재사용
  2. 별도 모바일 crew drawer/sheet 추가
- 모바일에서 크루가 2개 이상일 때도 전환 가능해야 한다.
- 모바일에서 메뉴가 화면 밖으로 잘리거나 사이드바 내부에 숨어 클릭 불가능하면 안 된다.

### 접근성/안전
- 크루 메뉴 항목은 button 또는 role/button + keyboard 접근 가능하게 처리한다.
- 메뉴 바깥 클릭/ESC로 닫히면 좋다. 기존 동작이 있다면 확장한다.

---

## 2. 랜딩 크루 카드의 상세보기/참여신청 버튼 위치 고정

### 목표
랜딩 페이지에서 크루 목록을 한눈에 볼 때 모든 카드의 `크루 상세보기`와 `참여 신청` 버튼이 카드 하단에 안정적으로 붙어 있어야 한다.
카드마다 description/leader 길이가 달라도 버튼 위치가 들쭉날쭉하면 안 된다.

### 필수 요구사항
- `index.html` CSS에서 일반 `.crew-card`가 같은 그리드 행 내에서 stretch 되고, 카드 내부는 flex column으로 버튼 영역이 하단에 밀리도록 조정한다.
- 권장 방식:
  - `.cards`, `.popular` grid는 `align-items: stretch`.
  - `.crew-card { height: 100%; }`
  - `.crew-actions { margin-top: auto; }`
  - 필요하면 `.crew-purpose`에 최소 높이/line-clamp를 적용하되, 모바일에서 너무 잘리지 않게 주의.
- featured 카드도 버튼 영역이 어색하게 중간에 뜨지 않도록 확인한다.
- 버튼 자체는 모바일에서 터치하기 쉽게 유지한다. 최소 높이 기존 `.btn` 토큰 유지.
- 하단 모바일 sticky CTA `.mcta`와 카드 버튼이 겹치지 않도록 확인한다.

---

## 3. 모바일에서 크루가 안 뜨는 문제 원인 확인 및 수정

### 범위
모바일에서 “크루가 안 뜸”은 두 경로 모두 확인해야 한다.

1. 랜딩 페이지 공개 크루 목록
   - URL: `crewup_official_site/index.html#crews`
   - `#crewGrid`, `#popularGrid`가 Supabase `crews` 결과를 렌더링해야 한다.
2. 작업실 내 크루 목록/active crew
   - URL: `crewup_official_site/app.html?workspace=1`
   - 로그인 상태에서 사용자의 joined/owned crew가 모바일 appbar/crew switcher에 보여야 한다.

### 반드시 점검할 것
- 모바일 viewport(예: 390x844, 430x932)에서 `window.CREWUP_CONFIG` 로드 여부.
- `window.__sb` 생성 여부.
- 공개 크루 query가 에러를 내는지 여부.
- `profiles!crews_owner_id_fkey(display_name)` relationship 때문에 모바일/배포 환경에서 query 전체가 실패하면, 공개 크루 목록은 fallback query를 사용해야 한다.
  - 예: 1차 query 실패 시 `profiles` join 없는 `crews` 단독 select로 다시 조회하고 ownerName은 `크루장` fallback.
- `portfolio_*` 컬럼이 아직 운영 DB에 적용되지 않은 환경에서 public crew query가 실패한다면, 신규 컬럼 없는 fallback select도 고려한다.
  - 단, schema 파일에는 필요한 ALTER가 이미 있거나 이전 작업에서 추가됐을 수 있으니 중복 없이 유지.
- 모바일 CSS/레이아웃 때문에 실제 렌더링된 카드가 숨겨지는지 확인.
- 모바일 appbar에서 크루 전환 메뉴가 사이드바 내부에 숨어서 접근 불가한지 확인.

### 실패 시 UX
- Supabase query 실패 시 조용히 empty 상태로 남기지 말고 console.warn에 원인을 남긴다.
- 공개 크루가 정말 0개일 때만 empty 문구 유지.
- query 실패와 데이터 0개는 구분한다.
- 사용자에게 alert 남발은 금지. 개발용 console.warn + 화면 empty/error 안내 정도.

---

## 4. 이미 완료된 랜딩 복귀 버튼 확인

- `sub_done.md` 기준으로 이미 완료됨:
  - 데스크톱 사이드바 footer `서비스 홈` 링크
  - 모바일 appbar 오른쪽 `서비스 홈` 링크
- 실제 코드에 둘 다 있으면 건드리지 말 것.
- 하나라도 누락되어 있으면 같은 스타일로 복구한다.

---

## 5. 검증

필수 검증:
- inline script 추출 후 `node --check` 통과.
- `git diff --check` 통과.
- 로컬 정적 서버에서 PC/모바일 viewport 모두 확인.
- Playwright 또는 브라우저로 최소 다음을 확인하고 `sub_done.md`에 기록한다.

### 데스크톱 작업실
- `app.html?workspace=1`에서 home-link가 보인다.
- mock/stub 세션 또는 실제 세션 환경에서 `window.__myCrews`에 여러 크루가 들어갈 때 `#crew-menu`에 모두 렌더링된다.
- 메뉴에서 두 번째 크루 선택 시 `.cs-name`, `.ab-name`, `window.__activeCrew.id`가 바뀐다.

### 모바일 작업실
- 390x844 또는 유사 viewport에서 `#appbar-crew`를 눌렀을 때 내 크루 목록을 볼 수 있다.
- 여러 크루 전환이 가능하다.
- `서비스 홈` 링크가 보인다.

### 랜딩 공개 크루 목록
- `index.html#crews`에서 PC/모바일 모두 카드가 렌더링된다.
- `크루 상세보기`/`참여 신청` 버튼이 카드 하단에 고정되어 보인다.
- public crew query 실패 fallback이 필요한 경우 작동한다.
- console/pageerror 없음.

### 산출물
- 변경 커밋 생성.
- `sub_done.md` 갱신.

## [Completed]
- 크루 생성/owner insert 구현됨.
- 참여 신청 생성/표시 구현됨.
- 참여 신청 수락/거절 실제 Supabase update/upsert 구현됨. 커밋: `1d8f7be Wire crew join request approvals`
- 공유함 업로드/미리보기 구현됨.
- 멤버별 개인 업로드 권한 토글은 실제 `crew_members.can_files/can_photos/can_videos` update로 동작한다고 사용자 확인.
- 멤버 관리/전체 권한 토글/포트폴리오 편집 관련 패치가 이전 `sub.md`에 지시되어 있고, 코드 일부가 이미 반영된 것으로 보임. 이번 작업에서는 해당 기능을 불필요하게 다시 재작성하지 말 것.
- 크루 관리/작업실에서 랜딩으로 돌아가는 버튼은 직전 `sub_done.md` 기준 완료:
  - 데스크톱 `.side-foot .home-link` → `index.html#home`
  - 모바일 `.appbar .home-link` → `index.html#home`

## [Agent Report Template]
[에이전트 제출용 _done.md 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 구현 요약:
- 내 크루 전체 목록 조회/저장 방식:
- 크루 전환 처리 방식:
- 모바일 크루 전환 UI 처리 방식:
- 랜딩 카드 버튼 하단 고정 처리 방식:
- 모바일에서 크루가 안 뜨던 원인:
- public crew query fallback 처리 여부:
- 랜딩 복귀 버튼 확인 결과:
- 기존 참여신청/공유함/멤버관리/포트폴리오 기능 영향:
- 검증 결과:
- 커밋:
- 에러 및 특이사항:
