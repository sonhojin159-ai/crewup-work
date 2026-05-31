# [Context]
Crew Up 정식 웹사이트 후보는 `/workspace/MA/crewup_official_site/index.html`에 새로 생성되어 있다.
하지만 실제 루트 진입 파일인 `/workspace/MA/index.html`은 예전 버전 그대로 남아 있어 사용자가 확인/배포 시 최신 정식 사이트 후보가 보이지 않을 수 있다.

현재 확인된 상태:
- 최신 후보: `/workspace/MA/crewup_official_site/index.html`
- 루트 진입 파일: `/workspace/MA/index.html` — 이전 랜딩 버전
- 기존 Netlify 폴더: `/workspace/MA/crewup_netlify/index.html` — 이전 배포용 버전이며 기존 지시에서 직접 덮어쓰기 금지였음
- 프로덕션 배포는 하지 않는다.

## [New Task]
이번 작업은 기존 기능을 새로 만들지 말고, 최신 정식 사이트 후보를 실제 확인 경로에 반영하는 패치 작업이다.

1. `/workspace/MA/crewup_official_site/index.html` 내용을 기준으로 `/workspace/MA/index.html`을 업데이트한다.
2. 업데이트 전에 최신 후보 파일에서 아래 표현을 한 번 더 점검하고, 공개 사이트 카피로 부자연스러운 경우 수정한다.
   - `실험`, `MVP`, `프로토타입`, `검증용`, `컨테이너`, `락인`, `small`, `소규모`
   - 단, HTML 태그 `<small>` 자체는 문법상 사용 가능하지만, 공개 문구에 `small/소규모` 의미가 노출되면 안 된다.
3. 지시서 원문에는 “외부 라이브러리 없이 동작” 조건이 있었으므로, Pretendard CDN 의존이 꼭 필요한지 점검한다.
   - 가능하면 시스템 폰트 fallback만으로 동작하게 정리한다.
   - CDN을 유지한다면 완료 보고서에 이유를 적는다.
4. JS 문법 체크를 실행한다.
5. 가능하면 로컬 서버 또는 파일 기준으로 브라우저 콘솔 에러가 없는지 확인한다.
6. `/workspace/MA/crewup_netlify/index.html`은 이번 작업에서 임의로 덮어쓰지 않는다. 사용자가 배포 반영을 승인하면 별도 지시로 처리한다.
7. git commit / Netlify deploy는 하지 않는다. Hermes가 보고서 확인 후 결정한다.

## [Completed]
- Claude Design 작업으로 `/workspace/MA/crewup_official_site/index.html` 생성 완료.
- 완료 보고서 `/workspace/MA/claude_design_crewup_official_site_done.md` 제출 완료.
- 기존 배포용 `/workspace/MA/crewup_netlify/index.html`은 이전 지시에 따라 수정하지 않았음.
- Hermes 검토 결과 `/workspace/MA/index.html`이 최신 후보로 업데이트되지 않은 상태임을 확인함.

## [Agent Report Template]
작업 완료 후 `/workspace/MA/sub_done.md`에 아래 형식으로 보고한다.

- 작업 상태: (성공적으로 완료됨 / 에러로 중단됨)
- 생성/수정된 파일 목록:
- 핵심 구현 요약: (코드 제외, 핵심 변경 설명)
- 공개 문구 점검 결과: (`실험`, `MVP`, `프로토타입`, `검증용`, `컨테이너`, `락인`, `small`, `소규모` 관련 조치)
- JS/브라우저 검증 결과:
- 에러 및 특이사항:
