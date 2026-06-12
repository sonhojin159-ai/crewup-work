---
title: Mobile Promo Page Builder
created: 2026-06-09
updated: 2026-06-12
type: concept
tags: [product, mvp, editor, mobile-preview, small-business]
sources: [raw/transcripts/kmong-mobile-promo-builder-summary.md]
confidence: high
---
# Mobile Promo Page Builder

소상공인이 사진·판매 품목·가격·이벤트·예약 정보를 넣으면 인스타 프로필에 걸 수 있는 모바일 안내페이지를 실시간 미리보기로 만드는 셀프 제작 제품 개념이다.

## 핵심 정의
`완성형 랜딩페이지 대행`이 아니라, 사용자가 입력한 데이터를 여러 양식에 자동 배치하고 한눈에 비교·편집·구매할 수 있게 하는 [[data-driven-template-market]]이다.

## MVP UX
1. 업종 선택
2. 양식 선택
3. 양식별 필요한 정보 입력
4. PC/모바일 미리보기 확인
5. 필요 시 AI에게 제한된 수정 요청
6. 구매 후 워터마크 제거 및 링크/HTML 제공

## 중요한 제품 원칙
- 모바일 안내페이지가 핵심이지만 제작자는 PC에서 작업할 수 있으므로 PC/모바일 미리보기를 같이 보여주는 방향이 좋다.
- 입력 패널은 엑셀식보다 사장님이 따라가기 쉬운 단계형 질문 UI가 적합하다.
- AI는 전체 생성보다 문구 다듬기, 섹션 순서, 강조도 조절에 제한적으로 쓰는 편이 좋다. 자세한 비용 원칙은 [[low-token-builder-flow]]에 둔다.

## 2026-06-12 최종 편집 사이트 MVP
최종 편집기 형태는 3패널 구조가 적합하다.

1. 좌측: 사장님 입력 패널 — 기본정보, 첫 화면 문구, 품목/가격 3개, 이벤트/혜택, 이미지 URL.
2. 중앙: 상품화 설명과 양식 맵 — 룩북형/포스터형/인스타형/예약형/사례형이 색상 스킨이 아니라 서로 다른 전환 목적을 가진다는 점을 보여준다.
3. 우측: 390px 모바일 실시간 미리보기 — 입력 변경과 양식 선택이 즉시 반영된다.

MVP 기능은 JSON 복사, 워터마크 토글, 네일샵/청소업체 프리셋, URL 파라미터 기반 양식 선택, 고객 전달용 단일 HTML 다운로드다. 현재 산출물은 `/home/ubuntu/crewup-work/landing-samples/data-driven-landing-template/final-mobile-builder-site/index.html`이다.

## 2026-06-12 사비 기준 수정
직전 최종 편집기는 편집 사이트처럼 보였지만 미리보기 본문이 너무 줄어들어 직판 구조가 약해졌다. 수정본은 `/home/ubuntu/crewup-work/landing-samples/data-driven-landing-template/final-sabri-editor-site/index.html`이다.

앞으로 이 제품의 미리보기/샘플은 고객 화면에 `사비 17단계` 용어를 직접 노출하지 않더라도, 내부 구조로는 반드시 다음 압축 블록을 유지해야 한다.

1. Hook / Hero: 대상 고객 호출, 큰 약속, 읽을 이유.
2. Problem: 고객이 막히는 이유와 이미 실패한 대안.
3. Mechanism: 해결 방식, 차별점, 진행 순서.
4. Proof: 사진, 후기, 수치, 위치, 전문성.
5. Offer: 가격, 보너스, 한정 조건, 리스크 제거.
6. Action: 구체적 문의 행동과 P.S. 리마인더.

축약형 모바일 페이지라도 Problem, Mechanism, Proof, Offer, Risk reversal, CTA, P.S.가 빠지면 단순 안내페이지가 되어 상품 가치가 약해진다.

## 관련
- [[industry-template-database]]
- [[watermark-purchase-flow]]
- [[kmong]]
