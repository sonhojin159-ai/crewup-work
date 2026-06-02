# SESSION-HANDOFF — Crew Up Supabase 연동 이어가기

- workspace: `/workspace/MA`
- official site path: `/workspace/MA/crewup_official_site`
- Windows path: `C:\Users\sonho\Desktop\MA\crewup_official_site`
- current status: Supabase MVP 연동 코드/문서/검수 완료, 실제 Supabase 프로젝트 값 입력 및 실서버 테스트 직전
- git status at handoff: clean 상태로 넘길 것

---

## 1. 현재까지 완료된 작업

### 1) Crew Up 공식 사이트 생성
- 공식 사이트 범위: `/workspace/MA/crewup_official_site`
- 주요 파일:
  - `index.html`: 방문자용 랜딩/크루 목록/참여 신청
  - `app.html`: 로그인 후 크루 작업실 앱
  - `supabase_schema.sql`: Supabase 테이블/RLS 스키마
  - `SUPABASE_SETUP.md`: Supabase 설정 가이드
  - `config.example.js`: 로컬 config 템플릿

### 2) Claude Code 작업 완료
- Supabase 연동 초안 작성
- 기존 `Crew App.html`을 `app.html`로 변경
- `index.html` 링크를 `app.html`로 연결
- Magic Link/Auth/session/data loader 초안 추가
- 공개 크루 목록/참여 신청 Supabase 연동 초안 추가

### 3) Codex 패치 완료
Codex가 Hermes 검토 지시서 `/workspace/MA/sub.md`를 기반으로 패치함.

적용된 핵심 패치:
- `index.html`
  - Supabase config 로딩 추가
  - 공개 크루 목록 query 보강
  - FK alias 적용: `profiles!crews_owner_id_fkey(display_name)`
  - query 실패 시 정적 카드 fallback 유지 + `console.warn`
  - 참여 신청 시 `join_requests`에 `crew_id`, `user_id`, `message` 저장
  - 중복 신청 `23505` 분기 처리
  - 기존 성공 UI와 DB insert 결과 UI 충돌 완화
- `app.html`
  - Magic Link 로그인 유지
  - config 없는 상태에서는 확인용 입장 흐름 유지
  - config 있는 상태에서는 확인용 버튼 숨김
  - 회원가입 닉네임을 OTP `options.data`에 전달
- `supabase_schema.sql`
  - RLS policy 앞에 `DROP POLICY IF EXISTS` 추가
  - 개발 중 반복 실행 가능하도록 개선
- `.gitignore`
  - `crewup_official_site/config.js` 제외 처리

### 4) Hermes 로컬 검증 완료
실행:

```bash
cd /workspace/MA/crewup_official_site
python3 -m http.server 4177 --bind 127.0.0.1
```

검증 결과:
- `http://127.0.0.1:4177/index.html?verify=codex`
  - 로딩 정상
  - console error 없음
- `http://127.0.0.1:4177/app.html?verify=codex`
  - 로딩 정상
  - console error 없음
  - 이메일 입력 → 확인용 입장 → 작업실 진입 정상
- inline JS `node --check` 문법 검사 통과

### 5) Anti-Gravity 검수 완료
검수 보고서:
- `/workspace/MA/test_done.md`

최종 판정:
- MVP 기준 승인 가능
- Critical/High 보안 이슈 없음
- 실제 Supabase 테스트는 아직 미수행

Anti-Gravity가 남긴 개선 항목:
1. `config.js` fetch 후 eval 구조를 `config.json` + `JSON.parse` 방식으로 바꾸면 보안/CSP 측면에서 더 좋음
2. `index.html`의 크루명 첫 글자 `initial`도 `escHtml(initial)` 처리 권장
3. Storage bucket은 생성 안내만 있고 `storage.objects` RLS/policy 안내가 부족함
4. `SECURITY DEFINER` helper 함수에 `SET search_path = public` 추가 권장

주의:
- Anti-Gravity는 위 항목을 “있으면 좋은 개선”으로 분류했고, 필수 수정은 없다고 판정함.
- 하지만 실제 연동 전 최소한 2번(initial escape), 4번(search_path)은 빠르게 반영하는 것이 좋음.
- 1번(config json 전환)은 구조 변경이라 실서버 테스트 전에 할지, MVP 테스트 후 할지 결정 필요.

---

## 2. 최근 커밋 로그

중요 커밋:
- `ab74e93 Add Anti-Gravity CrewUp Supabase review report`
- `d713a8e Add Anti-Gravity review instructions for CrewUp Supabase`
- `c079d12 Wire CrewUp site to Supabase auth and data`
- `4bc5fb6 Add Codex patch instructions for CrewUp Supabase review`
- `28268db docs: add Supabase MVP handoff`
- `9f76c15 Add Crew Up official site prototype`

---

## 3. 다음 세션에서 바로 해야 할 일

사용자 의도:
- “이제 연동하자”
- 실제 Supabase 프로젝트와 연결하려는 단계

### 다음 순번 권장

#### A. 빠른 보안 보강 후 실연동
실제 Supabase 테스트 전에 아래 2개는 Codex 또는 직접 패치 지시로 처리 권장:

1. `index.html` initial escape
   - `initial`을 HTML 문자열에 직접 합치지 말고 `escHtml(initial)` 사용

2. `supabase_schema.sql` helper function search_path 보강
   - `public.is_crew_member`
   - `public.is_crew_owner`
   - 가능하면 `public.handle_new_user`도 `SET search_path = public` 고려

선택 보강:
- `SUPABASE_SETUP.md`에 Storage object RLS 정책 안내 추가

#### B. Supabase 실제 프로젝트 설정
사용자에게 필요한 값:
- Supabase Project URL
- Supabase anon public key

절대 받거나 쓰면 안 되는 값:
- service_role key
- DB password를 프론트 config에 넣는 것

필요 파일:
- `/workspace/MA/crewup_official_site/config.js`

생성 형식:

```js
window.CREWUP_CONFIG = {
  SUPABASE_URL: "https://YOUR_PROJECT_ID.supabase.co",
  SUPABASE_ANON_KEY: "YOUR_SUPABASE_ANON_KEY"
};
```

`config.js`는 `.gitignore`에 포함되어 있으므로 커밋하지 않는다.

#### C. Supabase SQL 실행
Supabase Dashboard → SQL Editor에서 실행:
- `/workspace/MA/crewup_official_site/supabase_schema.sql`

주의:
- RLS policy는 DROP 후 CREATE라 반복 실행 가능
- Storage bucket은 SQL로 만들지 않고 Dashboard에서 생성

Storage bucket:
- name: `crew-files`
- Public bucket: OFF
- file size limit: 50 MB 권장

#### D. Auth Redirect URL 설정
현재 로컬 서버 방식 기준:

```text
http://localhost:4177/
http://localhost:4177/app.html
http://127.0.0.1:4177/
http://127.0.0.1:4177/app.html
```

문서에는 localhost 기준이 주로 적혀 있지만, 브라우저 검증은 127.0.0.1도 사용했으므로 둘 다 넣는 것이 안전함.

#### E. 로컬 서버 실행 및 실서버 테스트

```bash
cd /workspace/MA/crewup_official_site
python3 -m http.server 4177 --bind 127.0.0.1
```

테스트:
- `http://127.0.0.1:4177/index.html`
- `http://127.0.0.1:4177/app.html`

확인 항목:
1. app.html에서 Magic Link 이메일 전송
2. 이메일 링크 클릭 후 app.html 세션 진입
3. Supabase `profiles` row 생성 여부
4. `crews`에 테스트 공개 크루 데이터 삽입 후 index.html에서 목록 로딩 여부
5. 참여 신청 시 `join_requests` row 생성 여부
6. 로그인 안 된 상태에서 참여 신청 시 app.html 이동 여부
7. RLS 오류/console error 확인

---

## 4. 실제 테스트용 Supabase seed 예시

스키마 실행 후, 실제 공개 크루 목록 테스트를 위해 Supabase SQL Editor에서 현재 로그인 사용자 UUID를 알 수 없다면, owner/profile 관계 때문에 seed가 어렵다.

권장 테스트 순서:
1. app.html에서 Magic Link로 실제 로그인
2. Supabase `auth.users`와 `profiles`에서 생성된 user id 확인
3. 그 id를 사용해 `crews`와 `crew_members`를 삽입

예시:

```sql
-- USER_ID_HERE를 실제 profiles.id로 교체
insert into public.crews (name, description, category, is_public, owner_id)
values (
  'AI 숏폼 제작 크루',
  '광고 숏폼을 함께 기획하고 제작하는 크루입니다.',
  '콘텐츠 제작',
  true,
  'USER_ID_HERE'
)
returning id;

-- CREW_ID_HERE를 위 returning id로 교체
insert into public.crew_members (crew_id, user_id, role)
values ('CREW_ID_HERE', 'USER_ID_HERE', 'owner');
```

---

## 5. 새 세션 첫 프롬프트 추천

VS Code에서 Hermes를 새로 실행하면 아래처럼 시작하면 된다.

```text
/workspace/MA/SESSION-HANDOFF.md 읽고 Crew Up Supabase 실제 연동 이어가자.
먼저 Anti-Gravity 개선 항목 중 실연동 전에 바로 고칠 것과 나중에 해도 되는 것을 나눠서 판단하고,
Supabase Project URL/anon key를 config.js에 넣는 단계부터 진행하자.
```

만약 사용자가 Supabase 값을 바로 줄 경우:

```text
Project URL: ...
anon public key: ...
이 값으로 /workspace/MA/crewup_official_site/config.js 만들고 실제 Magic Link 테스트 준비해줘.
service_role key는 절대 쓰지 마.
```

---

## 6. 현재 운영 판단

현재 상태는 “Anti-Gravity 검수 완료, MVP 승인 가능, 실제 Supabase 연결 직전”이다.

다음 세션에서 선택지는 두 가지:

1. 빠른 MVP 실연동 우선
   - config.js 생성
   - SQL 실행 안내/확인
   - Redirect URL 설정
   - Magic Link/공개 크루/참여 신청 테스트

2. 보안 보강 후 실연동
   - initial escape
   - search_path 보강
   - Storage RLS 문서 보강
   - 그 후 config.js 생성 및 테스트

Hermes 권장:
- 실연동 전에 가벼운 보안 보강 2개(initial escape, search_path)는 먼저 처리
- config.js eval → config.json 전환은 MVP 실테스트 후 별도 패치로 진행해도 됨
