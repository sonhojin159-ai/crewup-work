---
type: operating-rule
created: 2026-06-07
tags:
  - obsidian
  - hermes
  - knowledge-base
---

# Obsidian Save Rules

Hermes와 각 모델/에이전트가 Obsidian에 지식을 저장할 때 따르는 규칙입니다.

## 저장할 것
- 반복 가능한 작업 방식
- 디자인/UX 패턴
- 프로젝트 의사결정 기준
- 체크리스트
- 모델/에이전트 역할 분담 규칙
- 사용자 행동 패턴, 자주 확인하는 항목, 작업 방향성, 디자인 선호, 선호 UI/UX 요소
- CrewUp에 적용 가능한 리서치 요약
- 유튜브/쇼츠/SEO 인사이트

## 사용자 맞춤 위키 규칙
- Obsidian의 최우선 역할은 단순 기록이 아니라 사용자를 이해해 매 작업 결과를 점점 더 개인화하는 것이다.
- 프로젝트를 진행하면서 사용자의 행동 패턴, 자주 확인하는 내용, 작업 방향성, 선호 디자인, 선호 UI/UX 요소, 반복 검수 기준을 누적 저장한다.
- 여러 프로젝트에 공통으로 적용되는 사용자 선호와 작업 방식은 `01_User/User Operating Profile.md`에 저장한다.
- 특정 프로젝트에만 적용되는 선호/결정은 해당 프로젝트 폴더의 Context, Design System, Checklist, Action Items에 저장한다.
- 다음 작업을 시작할 때는 필요한 경우 사용자 프로필과 관련 프로젝트 노트를 먼저 참고해 맞춤형 결과를 만든다.
- 단순 잡담이나 일회성 감정 표현이 아니라, 반복적으로 결과 품질을 높일 수 있는 패턴을 저장한다.

## 프로젝트별 위키 저장 규칙
- Obsidian은 CrewUp뿐 아니라 사용자의 모든 주요 프로젝트를 위한 개인/프로젝트 위키로 운영한다.
- 새 프로젝트가 시작되면 프로젝트별 폴더를 만들고, 최소한 다음 노트를 둔다.
  - `README.md`: 프로젝트 개요와 주요 링크
  - `Product Context.md` 또는 `Project Context.md`: 목적, 타깃, 핵심 방향, 용어 결정
  - `Action Items.md`: 다음 작업, 구현 후보, 검수할 항목
  - `Design System.md` 또는 `UX Rules.md`: 반복 UI/UX 기준이 있는 경우
  - `Checklist.md`: 출시/모바일/QA/운영 검수 기준이 있는 경우
- 프로젝트별로 저장할 내용:
  - 제품/기획 결정
  - 기능 요구사항
  - UI/UX 결정
  - 구현 액션 아이템
  - 검수 체크리스트
  - 다음 프로젝트에서도 재사용 가능한 인사이트
- 다음 프로젝트를 진행할 때는 필요한 경우 이전 프로젝트 노트를 검색/참고해 패턴, 체크리스트, 의사결정 기준을 재사용한다.
- 모든 대화를 원문 그대로 저장하지 말고, 중복을 제거해 짧은 결정/규칙/TODO 형태로 저장한다.
- 일회성 작업 완료 로그, 커밋 SHA, PR 번호, 임시 에러 로그는 저장하지 않는다.

## CrewUp 즉시 저장 규칙
- CrewUp 관련 제품 방향, 기능 요구사항, UI/UX 결정, 구현 액션 아이템, 검수 체크리스트는 사용자가 별도로 요청하지 않아도 즉시 Obsidian에 정리한다.
- 저장 위치는 내용에 따라 분류한다.
  - 제품/기획 결정: `10_CrewUp/CrewUp Product Context.md`
  - 해야 할 작업: `10_CrewUp/CrewUp Action Items.md`
  - 디자인/UI 규칙: `10_CrewUp/CrewUp Design System.md`
  - 모바일/랜딩 검수 기준: 관련 체크리스트 노트
  - 아직 분류가 애매한 아이디어: `00_Inbox/`

## 저장하지 않을 것
- 금방 낡는 작업 완료 로그
- 커밋 SHA / PR 번호 / 일회성 에러 로그
- 임시 TODO
- 비밀번호/API Key/토큰
- 코드 전문 대량 복사

## 파일명 규칙
- 날짜별 리서치: `YYYY-MM-DD 주제.md`
- 체크리스트: `프로젝트명 Checklist.md`
- 운영 규칙: `주제 Rules.md`
- 모델 보고서: `YYYY-MM-DD Agent - 주제.md`

## 폴더 규칙
- `00_Inbox`: 임시 수집
- `10_CrewUp`: CrewUp 제품/디자인/운영
- `20_AI_Agent`: 모델/agent 운영
- `30_Web_Design`: 디자인 리서치
- `40_YouTube`: 유튜브/쇼츠/광고 콘텐츠
- `90_Agent_Reports`: agent 완료 보고서 아카이브
