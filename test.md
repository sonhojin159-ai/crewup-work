# [Context]
Crew Up 공식 사이트는 `/workspace/MA/crewup_official_site`에 있다.

현재 단계는 Claude Code + Codex가 완료한 Supabase 연동 작업에 대한 Anti-Gravity 최종 검수 단계다.
Hermes는 이미 로컬 fallback 기준 검증을 완료했고, 이제 독립 검수원이 보안/코드/동작 리스크를 찾아야 한다.

관련 커밋:
- `c079d12 Wire CrewUp site to Supabase auth and data`
- `4bc5fb6 Add Codex patch instructions for CrewUp Supabase review`
- `28268db docs: add Supabase MVP handoff`

주요 파일:
- `crewup_official_site/index.html`
- `crewup_official_site/app.html`
- `crewup_official_site/supabase_schema.sql`
- `crewup_official_site/SUPABASE_SETUP.md`
- `crewup_official_site/config.example.js`
- `.gitignore`

현재 구현 요약:
- 기존 `Crew App.html`을 `app.html`로 rename
- 방문자용 `index.html`의 로그인/시작하기/작업실 이동 링크를 `app.html`로 연결
- `config.example.js`와 gitignore된 `config.js` 구조 추가
- Supabase client 초기화 추가
- `index.html` 공개 크루 목록 Supabase 로딩 추가
- `index.html` 참여 신청을 `join_requests`에 insert하도록 추가
- `app.html` Magic Link 로그인 및 세션 동기화 추가
- `app.html` 크루 메시지/노트/링크 로딩 일부 추가
- `supabase_schema.sql`에 테이블/RLS policy 추가
- RLS policy는 반복 실행 가능하도록 `DROP POLICY IF EXISTS` 보강
- config가 없을 때는 로컬 확인용 fallback 흐름 유지

Hermes 로컬 검증 완료:
- `python3 -m http.server 4177 --bind 127.0.0.1`
- `http://127.0.0.1:4177/index.html?verify=codex` 로딩 정상, console error 없음
- `http://127.0.0.1:4177/app.html?verify=codex` 로딩 정상, console error 없음
- config 없는 상태에서 이메일 입력 → 확인용 입장 → 작업실 진입 정상
- inline JS `node --check` 문법 검사 통과

## [New Task]
Anti-Gravity는 아래 항목을 독립적으로 검수한다. 코드를 수정하지 말고, 문제를 `test_done.md`에 보고한다.

### 1. 보안 검수
아래를 중점적으로 본다.

- `index.html`, `app.html`에서 XSS 가능성이 있는 `innerHTML` 사용 여부
  - 사용자 입력/DB 데이터가 직접 HTML로 들어가는지 확인
  - `escHtml`, `textContent` 처리 누락 여부 확인
- `config.js` 로딩 방식 검토
  - 현재 `config.js` 내용을 fetch 후 eval하는 구조가 있다.
  - 정적 호스팅 환경에서 보안상 허용 가능한지, 더 안전한 대안이 필요한지 판단
  - 특히 `config.js`가 동일 origin이어도 XSS 표면을 넓히는지 평가
- Supabase anon key 사용 범위 확인
  - service_role 키가 절대 프론트에 들어가지 않도록 문서/예시 확인
- RLS policy 검토
  - 비로그인 사용자가 볼 수 있는 데이터 범위가 과도하지 않은지
  - 크루 멤버/가입 신청/메시지/노트/링크/파일 메타데이터 접근 정책이 의도와 맞는지
  - helper function `SECURITY DEFINER` 사용이 안전한지
- 참여 신청 중복/실패 처리에서 정보 노출이나 잘못된 성공 표시가 없는지
- Storage bucket 관련 누락된 RLS/storage policy 안내가 없는지

### 2. 코드/로직 검수
아래를 중점적으로 본다.

- `index.html`의 공개 크루 로딩 query:
  - `profiles!crews_owner_id_fkey(display_name)`가 현재 schema의 FK 이름과 실제로 맞는지 확인
  - 실패 시 정적 fallback이 유지되는지 확인
- 참여 신청 흐름:
  - 로그인 안 된 상태에서 app.html로 이동하는지
  - 로그인 된 상태에서 `join_requests`에 `crew_id`, `user_id`, `message`가 들어가는지
  - 기존 모달 성공 UI와 새 Supabase insert 결과 UI가 충돌하지 않는지
- `app.html` Magic Link 흐름:
  - config 없음: 확인용 입장 정상
  - config 있음: 확인용 버튼 숨김, Magic Link만 사용
  - Redirect URL 문서와 실제 코드의 `emailRedirectTo: location.href`가 맞는지
- 회원가입 닉네임 처리:
  - `options.data.display_name`이 `handle_new_user()`의 `NEW.raw_user_meta_data`를 사용하지 않는 현재 schema와 충돌하지 않는지
  - 실제로 `profiles.display_name`에 닉네임이 저장되는지, 아니면 이메일로만 저장되는지 확인
- `supabase_schema.sql` 반복 실행 가능성:
  - 모든 policy 앞에 `DROP POLICY IF EXISTS`가 있는지
  - 함수/트리거/테이블 재실행 시 문제 없는지
- 삭제된 `Crew App.html` → `app.html` rename으로 깨진 링크가 없는지

### 3. 문서 검수
- `SUPABASE_SETUP.md`가 실제 실행 방식과 일치하는지
- Redirect URL 안내가 맞는지
- config 없을 때 동작 설명이 실제 UI와 맞는지
- Storage bucket 생성만 안내되어 있고 Storage object RLS/policy가 빠져 있지는 않은지 확인

### 4. 실제 브라우저 검수
가능하면 다음을 직접 실행해서 확인한다.

```bash
cd /workspace/MA/crewup_official_site
python3 -m http.server 4177 --bind 127.0.0.1
```

브라우저:
- `http://127.0.0.1:4177/index.html`
- `http://127.0.0.1:4177/app.html`

확인 항목:
- console error/warn
- 모바일 폭에서 CTA/모달 깨짐 여부
- 참여 신청 모달 열림/닫힘
- app.html 확인용 입장 흐름
- 깨진 링크 여부

### 5. 실제 Supabase 테스트 가능 시
실제 Supabase 프로젝트 config가 준비되어 있으면 다음까지 확인한다.
단, service_role key는 절대 사용하지 않는다.

- Magic Link 이메일 전송
- Magic Link 클릭 후 app.html 세션 진입
- 공개 크루 목록 로딩
- 참여 신청 insert
- RLS 때문에 비정상 접근이 차단되는지

실제 config가 없으면 “실서버 Supabase 테스트 미수행”으로 명확히 표시한다.

## [Completed]
완료된 작업:
- Claude Code: Supabase 연동 초안 작성
- Codex: Hermes 검토 후 패치 적용
- Hermes: 로컬 fallback 브라우저 검증 및 커밋 완료

아직 완료되지 않은 작업:
- Anti-Gravity 독립 보안/코드/동작 검수
- 실제 Supabase 프로젝트에 `config.js`를 넣은 실서버 테스트
- 검수 결과에 따른 버그 수정 여부 결정

## [Agent Report Template]
`test_done.md`에 아래 형식으로 보고한다.

- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 검수 대상 커밋:
- 검수한 파일 목록:
- 보안 이슈:
  - Critical:
  - High:
  - Medium:
  - Low:
- 코드/로직 이슈:
- 문서 이슈:
- 브라우저 검증 결과:
  - index.html:
  - app.html:
  - console error/warn:
  - 모바일/모달/링크:
- 실제 Supabase 테스트 여부:
- 반드시 수정해야 할 항목:
- 있으면 좋은 개선 항목:
- 최종 판정: (승인 가능 / 수정 후 재검수 필요)
