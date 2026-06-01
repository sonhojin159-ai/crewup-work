# [Context]
Crew Up 공식 사이트는 `/workspace/MA/crewup_official_site`에 있으며, 현재 Claude Code가 Supabase 연동 초안을 완료했다.

주요 파일:
- `crewup_official_site/index.html`: 방문자용 랜딩/크루 목록/참여 신청
- `crewup_official_site/app.html`: 로그인 후 크루 작업실 앱
- `crewup_official_site/supabase_schema.sql`: Supabase DB/RLS 스키마
- `crewup_official_site/SUPABASE_SETUP.md`: 설정 가이드
- `crewup_official_site/config.example.js`: anon key 예시

Hermes 검토 결과, `index.html` 자체에는 Supabase 초기화/공개 크루 목록/참여 신청 연동 코드가 추가되어 있으나, 실제 Supabase 연결 시 깨질 수 있는 부분과 문서 불일치가 남아 있다.

## [New Task]
이번 작업은 신규 메인 구현이 아니라 기존 Claude Code 완료분의 패치/정리다. 아래 항목만 수정한다.

1. `SUPABASE_SETUP.md`의 Redirect URL 수정
   - 현재 로컬 실행 명령이 `cd /workspace/MA/crewup_official_site && python3 -m http.server 4177` 이므로 실제 앱 주소는 아래가 맞다.
     - `http://localhost:4177/`
     - `http://localhost:4177/app.html`
   - 문서에 있는 `http://localhost:4177/crewup_official_site/app.html`는 현재 실행 방식과 불일치하므로 제거하거나 “상위 폴더에서 서버를 띄울 때만”이라고 명확히 구분한다.

2. `SUPABASE_SETUP.md`의 config 없을 때 동작 설명 정정
   - 현재 `app.html`은 config가 없으면 오프라인 확인용 입장 버튼으로 앱에 들어갈 수 있다.
   - 문서에는 “로그인 시도 시 설정 필요 안내”라고 되어 있어 실제 동작과 다르다.
   - 실제 동작에 맞게 수정하거나, 정말 설정 필요 안내가 목적이라면 UI/JS를 그 동작에 맞게 고친다.
   - 단, 사용자 화면에 `데모`라는 표현이 드러나지 않게 한다. 문서 내부 설명은 가능하지만, 제품 화면 문구는 `확인용`, `오프라인 확인` 정도로 유지한다.

3. `index.html` 참여 신청 Supabase insert 보강
   - 현재 `join_requests` insert는 `{ crew_id, user_id }`만 저장한다.
   - 참여 신청 모달에 사용자가 입력하는 메시지/소개 필드가 있다면 해당 값을 `message` 컬럼에도 저장하도록 연결한다.
   - 이미 신청한 경우(23505) 사용자에게 명확하게 안내한다.
   - Supabase 오류가 발생해도 기존 성공 UI가 무조건 뜨지 않도록, 실제 DB insert 성공/중복/실패 상태에 맞춰 안내를 분기한다.

4. `index.html` 공개 크루 목록 query/렌더링 안정화
   - `.select("id, name, description, category, owner_id, profiles(display_name)")`가 Supabase FK relationship 문제로 실패할 수 있다.
   - 실패 시 기존 정적 카드 fallback이 유지되는 것은 좋지만, 개발자가 원인을 알 수 있도록 `console.warn`으로 최소한의 오류 메시지를 남긴다.
   - 가능하면 FK alias를 명시한다: 예) `profiles!crews_owner_id_fkey(display_name)` 형태가 실제 스키마에서 동작하는지 확인 후 적용한다.

5. `supabase_schema.sql` 재실행 가능성 또는 문서 정리
   - 현재 `CREATE POLICY`에 `IF NOT EXISTS`가 없어 같은 SQL을 재실행하면 policy already exists 오류가 날 수 있다.
   - 둘 중 하나를 선택한다.
     - A안: 스키마를 fresh project 1회 실행용으로 명확히 문서화하고 “재실행 전 policy/table drop 필요” 안내 추가
     - B안: DROP POLICY IF EXISTS를 각 policy 앞에 추가해서 반복 실행 가능하게 개선
   - Hermes 권장: B안. 개발 중 RLS 수정이 잦기 때문이다.

6. `app.html` 회원가입 닉네임 처리
   - 회원가입 폼에 닉네임 입력칸이 있으나 현재 Supabase `signInWithOtp({ email })`에 닉네임이 전달되지 않는다.
   - `options.data` 또는 로그인 이후 profile update 방식으로 `profiles.display_name`에 닉네임이 저장되도록 보강한다.
   - `handle_new_user()`가 기본값으로 이메일을 display_name에 넣는 구조와 충돌하지 않게 처리한다.

7. 변경 후 검증
   - `python3 -m http.server 4177`로 `crewup_official_site`를 띄운다.
   - `http://localhost:4177/index.html`에서 console error가 없는지 확인한다.
   - `http://localhost:4177/app.html`에서 config 없는 오프라인 확인용 흐름이 깨지지 않는지 확인한다.
   - 가능한 경우 Supabase 실제 config로 Magic Link 전송, 공개 크루 로딩, 참여 신청 insert까지 확인한다.

## [Completed]
Claude Code가 완료한 것으로 보고된 내용:
- `Crew App.html`을 `app.html`로 전환
- `index.html` 로그인/시작하기/작업실 이동 링크를 `app.html`로 연결
- `config.example.js`, `.gitignore`의 `crewup_official_site/config.js` 추가
- `supabase_schema.sql` 생성
- `SUPABASE_SETUP.md` 생성
- `index.html` 공개 크루 목록/참여 신청 Supabase 연동 초안 추가
- `app.html` Magic Link/Auth/session/data loader 초안 추가

Hermes 검증 완료:
- config 없는 상태에서 `index.html` 로딩 시 JS console error 없음
- config 없는 상태에서 `app.html` 로그인 폼 → 확인용 입장 → 작업실 진입 흐름 정상
- `.gitignore`에 `crewup_official_site/config.js` 포함 확인

## [Agent Report Template]
[에이전트 제출용 _done.md 양식]
- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 수정 요약: (코드 전문 제외, 위 New Task 항목별로 처리 결과 설명)
- 검증 결과:
  - index.html console error:
  - app.html config 없는 오프라인 확인 흐름:
  - Supabase 실제 연결 테스트 여부:
- 에러 및 특이사항:
