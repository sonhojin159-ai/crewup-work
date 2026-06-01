# main.md 작업 완료 보고

**작업일**: 2026-06-02  
**작업자**: Claude (claude-sonnet-4-6)

---

## 완료된 작업 목록

### 1. 파일 이름 변경
- `Crew App.html` → `app.html` 완료
- `index.html` 내 `Crew App.html` 링크 4곳 모두 `app.html` 로 업데이트

### 2. .gitignore 업데이트
- `crewup_official_site/config.js` 항목 추가
- 실제 Supabase 키가 포함된 `config.js` 가 git에 커밋되지 않도록 보호

### 3. config.example.js 생성
- 위치: `crewup_official_site/config.example.js`
- Supabase URL과 anon key 플레이스홀더 포함
- 사용자가 복사 후 실제 값을 채워 `config.js` 로 저장

### 4. supabase_schema.sql 생성
- 위치: `crewup_official_site/supabase_schema.sql`
- 8개 테이블 정의:
  - `profiles` (auth.users 자동 연동 트리거 포함)
  - `crews`, `crew_members`, `join_requests`
  - `crew_messages`, `crew_notes`, `crew_links`, `crew_files`
- RLS 활성화 + 정책 정의:
  - 공개 크루는 누구나 조회
  - 비공개 크루는 멤버만 조회
  - 크루장이 멤버 관리
  - 각 테이블별 SELECT/INSERT/UPDATE/DELETE 정책
- 헬퍼 함수: `is_crew_member()`, `is_crew_owner()`
- `crew-files` Storage 버킷 설명 주석 포함 (SQL로 생성 불가, 대시보드에서 생성 필요)

### 5. SUPABASE_SETUP.md 생성
- 위치: `crewup_official_site/SUPABASE_SETUP.md`
- 단계별 연동 가이드:
  1. Supabase 프로젝트 생성
  2. config.js 만들기
  3. 스키마 SQL 실행
  4. Storage 버킷 생성 (`crew-files`, 비공개)
  5. Auth Redirect URL 설정 (`http://localhost:4177`)
  6. 로컬 서버 실행 방법
  7. Magic Link 로그인 흐름 설명
  8. 오프라인(미설정) 모드 동작 설명
  9. 트러블슈팅 표

### 6. app.html — Supabase 연동

**`<head>` 추가:**
- `<script src="config.js" onerror="void 0"></script>` — 없어도 에러 없음
- Supabase JS v2 CDN
- `window.__sb` 초기화 스크립트 (플레이스홀더 감지 → 미설정 시 건너뜀)
- Supabase 활성 시 localStorage auth 키 초기화 (세션 충돌 방지)

**기존 IIFE 수정:**
- auth 복원: `window.__sb` 없을 때만 localStorage에서 복원
- magic-link 폼 submit: Supabase 설정 시 `signInWithOtp()` 호출, 에러 시 롤백
- demo-enter 버튼: Supabase 활성 시 숨김 (실제 메일 링크로만 입장)
- logout: `window.__sb.auth.signOut()` 추가

**추가 `<script>` 블록 (세션 + 데이터 로더):**
- `onAuthStateChange`: 세션 변경 시 `body.dataset.auth` 자동 동기화
- `loadCrewData(userId)`: 소속 크루 조회 → 사이드바 크루 이름 반영, `crewstate` 전환
- `loadMessages(crewId)`: 채팅 메시지 로드 → `#chat-scroll` 렌더링
- 채팅 compose: 메시지 전송 시 Supabase에도 저장
- `loadNotes(crewId)`: 노트 목록 로드 → 노트 뷰에 렌더링
- `loadLinks(crewId)`: 링크 목록 로드 → 링크 뷰에 렌더링
- Supabase 미설정 시 모든 함수 스킵, 기존 하드코딩 UI 그대로 유지

### 7. index.html — Supabase 연동

**`<head>` 추가:**
- `config.js` + Supabase JS v2 CDN + `window.__sb` 초기화 스크립트

**추가 `<script>` 블록 (크루 목록 + 가입 신청):**
- 공개 크루 목록: `crews` 테이블에서 조회 → `#crewGrid` 동적 렌더링
  - Supabase 데이터 없거나 오류 시 하드코딩 카드 그대로 유지
- 가입 신청 인터셉트:
  - 비로그인: confirm 후 `app.html` 로 이동 (로그인 유도)
  - 로그인: `join_requests` INSERT, 중복(23505) 에러 시 "이미 신청한 크루예요" 알림

### 8. 파일 업로드
- `파일 업로드는 준비 중이에요` 토스트 유지 (변경 없음)
- `supabase_schema.sql`에 `crew_files` 테이블 + Storage 버킷 안내 포함
- 스토리지 업로드 구현은 파일 업로드 버튼 활성화 이후 단계

---

## 검증 결과

| 항목 | 결과 |
|---|---|
| 파일 존재 확인 | ✅ app.html, index.html, config.example.js, supabase_schema.sql, SUPABASE_SETUP.md |
| JS 문법 검사 | ✅ app.html (4개 블록), index.html (5개 블록) 모두 오류 없음 |
| 금지 문구 검사 | ✅ "프로토타입", "데모" 없음 |
| 파일명 변경 | ✅ Crew App.html → app.html, index.html 링크 4곳 수정 |
| 로컬 서버 (4177) | ✅ 모든 파일 HTTP 200 응답 |
| Supabase 미설정 시 | ✅ 기존 UI 그대로 동작 (fallback) |
| 보안 | ✅ anon key 플레이스홀더만 사용, config.js 미커밋 |

---

## 사용자가 해야 할 작업

1. **Supabase 프로젝트 생성** — [supabase.com](https://supabase.com)
2. **`config.js` 만들기** — `config.example.js` 복사 후 실제 URL/key 입력
3. **스키마 실행** — Supabase SQL Editor에서 `supabase_schema.sql` 전체 실행
4. **Storage 버킷 생성** — 대시보드 → Storage → `crew-files` (비공개)
5. **Redirect URL 설정** — Authentication → URL Configuration → `http://localhost:4177` 추가
6. **로컬 테스트** — `python3 -m http.server 4177` 후 브라우저에서 확인

자세한 내용은 `SUPABASE_SETUP.md` 참조.

---

## 이번 단계에서 구현하지 않은 기능 (main.md 명시)

- 결제 / 네이티브 앱
- 실시간 협업 문서 / 화상회의
- 실시간 채팅 구독 (SELECT만 구현)
- 파일 실제 업로드 (스키마는 준비됨)
