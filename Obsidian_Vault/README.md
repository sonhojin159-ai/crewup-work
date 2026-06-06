# Obsidian Vault for AI Agent Operations

이 Vault는 Hermes를 관제탑으로 두고 OpenAI, Claude, Grok, Codex, Anti-Gravity 등 각 모델/CLI의 결과를 누적 저장하기 위한 지식베이스입니다.

## 폴더 구조

- `00_Inbox`: 임시 수집함
- `10_CrewUp`: CrewUp 제품/디자인/모바일/운영 지식
- `20_AI_Agent`: 모델 라우팅, 에이전트 보고서 표준, 저장 규칙
- `30_Web_Design`: 웹디자인/UX 리서치
- `40_YouTube`: 유튜브/쇼츠/광고/SEO 자료
- `50_Daily`: 데일리 노트
- `90_Agent_Reports`: 각 모델/에이전트 완료 보고서 아카이브
- `98_Attachments`: 첨부파일
- `99_Templates`: Obsidian 템플릿

## 시작 노트

- [[CrewUp Product Context]]
- [[CrewUp Design System]]
- [[CrewUp Mobile UX Checklist]]
- [[Model Routing Rules]]
- [[Agent Report Standard]]
- [[Obsidian Save Rules]]

## Hermes 사용 규칙

Hermes는 이 Vault에 다음 종류의 내용을 저장합니다.

1. 반복 가능한 작업 방식
2. 웹디자인/UX 패턴
3. 모델/에이전트 역할 분담 규칙
4. CrewUp에 적용 가능한 리서치 요약
5. 작업 지시서로 전환할 후보

Hermes는 다음 내용은 저장하지 않습니다.

1. API Key, 비밀번호, 토큰
2. 금방 낡는 작업 완료 로그
3. 커밋 SHA/PR 번호 같은 일회성 정보
4. 코드 전문 대량 복사

## Obsidian에서 여는 방법

Obsidian 앱 실행 → Open folder as vault → 아래 경로 선택:

`/workspace/MA/Obsidian_Vault`

Windows에서 보이는 실제 경로는 현재 Docker/WSL 마운트 구조에 따라 다를 수 있습니다. 현재 Hermes 내부 기준 Vault 경로는 `/workspace/MA/Obsidian_Vault`입니다.
