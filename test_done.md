# Crew Up Supabase MVP 검수 완료 보고서

## 작업 상태
- 성공적으로 완료됨

## 검수 대상 커밋
- `d713a8e109d8b99e58a3d396885e97be0b58f8bd`

## 검수한 파일 목록
- `/workspace/MA/crewup_official_site/index.html`
- `/workspace/MA/crewup_official_site/app.html`
- `/workspace/MA/crewup_official_site/supabase_schema.sql`
- `/workspace/MA/crewup_official_site/SUPABASE_SETUP.md`
- `/workspace/MA/crewup_official_site/config.example.js`

## 보안 이슈
- **Critical**: 없음
- **High**: 없음
- **Medium**:
  - **Web Worker eval을 통한 config.js 로드**: config.js 유무에 따른 콘솔 에러 발생을 막기 위해 Web Worker 내부에서 fetch 후 eval하는 방식을 채택하고 있습니다. 동일 origin에 위치해 있어 직접적인 권한 상승은 낮으나, origin 내 파일 업로드나 경로 조작 취약점이 있을 경우 XSS 공격 표면이 될 수 있으며 `unsafe-eval` 정책을 요구하여 CSP 보안 규격을 준수하기 어렵게 만듭니다.
    - *개선안*: 설정 파일을 JSON 포맷(`config.json`)으로 전환하고, `JSON.parse`를 통해 객체로 디코딩하여 설정하도록 수정할 것을 권장합니다.
- **Low**:
  - **첫 글자(initial)의 escHtml 이스케이프 누락**: `index.html` 1986라인 부근에서 크루명의 첫 글자(`initial = name.charAt(0)`)를 HTML에 삽입할 때 `escHtml` 처리를 하지 않고 직접 문자열에 합산하여 `article.innerHTML`에 대입합니다. 만약 크루명이 `<` 등의 특수문자로 시작하면 HTML 구조가 깨질 수 있습니다.
    - *개선안*: `escHtml(initial)`로 변경하여 안전하게 렌더링되도록 수정해야 합니다.
  - **Helper 함수 내 search_path 누락**: `supabase_schema.sql`에 정의된 `SECURITY DEFINER` 권한의 `is_crew_member` 및 `is_crew_owner` 함수에 `SET search_path = public` 설정이 빠져 있습니다. 악의적인 스키마 설정이나 다중 테넌트 구성 시 보안 취약점이 될 수 있습니다.
    - *개선안*: 해당 SQL 함수 정의 마지막에 `SET search_path = public`을 명시해야 합니다.

## 코드/로직 이슈
- 없음.
  - `index.html` 내 공개 크루 목록을 가져오는 select 쿼리(`.select("id, name, description, category, owner_id, profiles!crews_owner_id_fkey(display_name)")`)가 `supabase_schema.sql`에 생성되는 FK 제약사항 및 컬럼명과 정상적으로 일치합니다.
  - 참여 신청 모달에서 사용자가 입력한 소개 메시지가 `join_requests` 테이블의 `message` 필드에 정상적으로 반영됩니다.
  - 이미 신청한 크루에 대해 재신청 시 발생하는 DB unique constraint 에러(PostgreSQL 에러코드 `23505`) 분기 처리가 정상 구현되어 있습니다.
  - `supabase_schema.sql` 파일 내 모든 RLS 정책 생성 코드 전면에 `DROP POLICY IF EXISTS` 처리가 완료되어 스키마 재실행에 문제가 없습니다.

## 문서 이슈
- **Storage Object RLS 정책 안내 누락**: `SUPABASE_SETUP.md`에 `crew-files` 버킷 생성 지침만 안내되어 있고, 버킷이 private일 때 사용자들이 파일을 업로드/다운로드할 수 있도록 보장하는 `storage.objects` 관련 RLS 정책 정의 가이드가 누락되었습니다.
  - *개선안*: `SUPABASE_SETUP.md` 또는 `supabase_schema.sql` 하단에 storage RLS 정책 적용 방법(예: `storage.objects` 테이블에 대한 select/insert 정책)을 함께 명시할 필요가 있습니다.

## 브라우저 검증 결과
- **index.html**: 정상 로드됨. '참여 신청' 모달이 오버레이 형태로 올바르게 열리고 닫히는 것을 확인했습니다.
- **app.html**: 정상 로드됨. config가 없는 오프라인 상태에서도 '확인용 입장' 플로우가 깨지지 않고 자연스럽게 작동합니다.
- **console error/warn**: JS 콘솔 에러 및 경고는 발생하지 않았습니다. 유일하게 `/favicon.ico`에 대한 404 리소스 로드 실패 로그만 확인되었으며 이는 서비스 동작에 아무런 영향을 주지 않습니다.
- **모바일/모달/링크**: 모바일 반응형 뷰포트(375x812)에서도 모달과 CTA 버튼이 정상 동작함을 확인했습니다. 구 버전 파일(`Crew App.html`, `Crew Up.html`) 링크 역시 전체 검사 결과 남아있지 않으며 깨진 링크가 없습니다.

## 실제 Supabase 테스트 여부
- **실서버 Supabase 테스트 미수행**

## 반드시 수정해야 할 항목
- 없음 (보안 취약점 중 Critical/High 등급 및 런타임 동작을 방해하는 치명적인 버그가 발견되지 않음).

## 있으면 좋은 개선 항목
1. **config.js -> config.json 전환**: `eval` 제거 및 CSP 보안 규격을 충족하기 위함.
2. **initial 변수 이스케이프**: 크루 카드 렌더링 시 첫 글자 `initial`에 `escHtml(initial)` 적용.
3. **Storage RLS 정책 가이드 보완**: `SUPABASE_SETUP.md` 파일에 `storage.objects` 접근용 정책 가이드라인 추가.
4. **Helper 함수 보안 패치**: `is_crew_member`, `is_crew_owner` 함수에 `SET search_path = public` 추가.

## 최종 판정
- **승인 가능** (안정성 및 보안 수준이 MVP 기준을 충족하므로 즉시 승인 가능하나, 위 개선 항목들을 반영하면 완성도가 더욱 높아질 것입니다).
