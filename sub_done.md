# sub_done — Crew Up 실연동 전 최소 보안 보강

- 작업 상태: 성공적으로 완료됨

- 생성/수정된 파일 목록:
  - 수정: `crewup_official_site/index.html`
  - 수정: `crewup_official_site/supabase_schema.sql`
  - 수정: `crewup_official_site/SUPABASE_SETUP.md`

- 핵심 수정 요약:
  - initial escape 처리 여부: 완료. Supabase 공개 크루 렌더링 시 크루명에서 파생된 `initial` 출력에 `escHtml(initial)`을 적용함.
  - helper function `SET search_path = public` 처리 여부: 완료. `public.handle_new_user`, `public.is_crew_member`, `public.is_crew_owner` 함수에 `SET search_path = public`을 추가함.
  - Storage RLS/policy 문서 보강 여부: 완료. `crew-files` 비공개 버킷 유지, `storage.objects` policy 점검 필요, 업로드/조회/삭제 권한 방향, service_role key 브라우저 사용 금지 안내를 `SUPABASE_SETUP.md`에 추가함.

- 검증 결과:
  - index.html console error: 없음. `http://127.0.0.1:4178/index.html?verify=directpatch`에서 확인.
  - app.html config 없는 오프라인 확인 흐름: 정상. 이메일 입력 → 확인용 입장 → 작업실 대시보드 진입 확인.
  - SQL 문법/구조 확인: helper function 3개 모두 `SET search_path = public` 포함 확인. SQL 파일은 Supabase Dashboard에서 최종 실행 검증 필요.
  - Supabase 실제 연결 테스트 여부: 미수행. 아직 실제 Project URL/anon public key가 입력되지 않은 단계임.

- 에러 및 특이사항:
  - 기존 4177 포트는 이미 다른 프로세스가 사용 중이라, 로컬 브라우저 검증은 4178 포트에서 수행함.
  - `crewup_official_site/config.js`는 생성하지 않았고, 비공개 키도 입력하지 않았음.
