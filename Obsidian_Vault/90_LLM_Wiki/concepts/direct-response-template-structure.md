---
title: Direct Response Template Structure
created: 2026-06-10
updated: 2026-06-10
type: concept
tags: [template, strategy, product, small-business]
sources: [raw/transcripts/sabri-17step-nail-template-note.md]
confidence: medium
---
# Direct Response Template Structure

Sabri Suby식 17단계 세일즈 메시지 흐름은 [[mobile-promo-page-builder]] 자체의 판매 상세페이지뿐 아니라, 실제로 소상공인에게 제공할 랜딩페이지 양식에도 적용해야 한다.

## 핵심 판단
사용자가 명확히 수정한 방향은 다음이다.

> “우리가 만드는 랜딩페이지 양식에 적용되어야지.”

즉, 네일샵·피부관리·청소업 등 업종별 템플릿은 단순히 예쁜 섹션 나열이 아니라 `문제 인식 → 해결책 → 증거 → 오퍼 → 위험 제거 → 예약 CTA`의 설득 흐름을 내장해야 한다.

## 17단계의 템플릿 적용 방식
1. 대상 고객 호출
2. 강한 헤드라인
3. 약속을 보조하는 설명
4. 호기심 bullet
5. 문제 선명화
6. 해결책 제시
7. 신뢰/자격
8. 혜택 상세화
9. 증거/후기
10. 핵심 오퍼
11. 보너스
12. 가치 스택
13. 가격 공개
14. 희소성
15. 보증/위험 제거
16. CTA
17. P.S. 경고/리마인더

## 양식화 원칙
17단계를 17개 고정 섹션으로 그대로 노출하면 모바일 페이지가 길고 부담스러워진다. 따라서 `세일즈 단계`와 `화면 섹션`을 분리한다.

```text
전략 레이어: 17-step sales logic
콘텐츠 레이어: 업종별 입력 필드
렌더링 레이어: 5~7개 모바일 섹션
스타일 레이어: lookbook/poster/instagram/calendar/direct-response 등 시각 테마
```

양식은 `섹션 블록` 단위로 관리한다. 각 블록은 여러 세일즈 단계를 흡수한다.

1. Hero Block: 대상 고객 호출, 헤드라인, 약속 보강, CTA.
2. Problem Block: 불편함, 실패한 대안, 고객 심리.
3. Solution Block: 해결책, 작동 방식, 차별점.
4. Proof Block: 사진, 후기, 숫자, 자격.
5. Offer Block: 가격, 보너스, 가치 스택, 희소성, 보증.
6. Action Block: 예약/문의 방법, FAQ, P.S.

## 데이터 모델 방향
각 업종 템플릿은 아래처럼 `sales_story` 데이터를 갖는다.

```json
{
  "audience_callout": "네일샵 가격표 찾다 지친 분께",
  "big_promise": "이번 달 아트와 가격, 예약 전 한 화면에서 끝내세요",
  "problem_points": ["가격이 흩어져 있음", "제거 비용이 불명확함"],
  "solution_summary": "사진·가격표·예약 안내를 한 페이지에 정리",
  "proof_items": ["후기 평점", "시술 사진", "고객 후기"],
  "offer": {"name": "첫 방문 패키지", "price": "79,000원부터"},
  "risk_reversal": "예약 전 손톱 사진 상담",
  "cta": "카카오톡으로 예약 문의하기",
  "ps": "혜택은 예약 확정 순서로 마감됩니다"
}
```

## 첫 적용 예시
네일샵용 샘플을 생성했다.

```text
/home/ubuntu/crewup-work/landing-samples/data-driven-landing-template/sabri-17step-nail/index.html
```

이 샘플은 [[industry-template-database]]의 네일샵 양식 데이터에 추가할 수 있는 `직접반응형 예약 전환 템플릿` 후보이며, [[data-driven-template-market]]에서는 `예약 전환형`, `세일즈 스토리형`, `direct-response` 양식으로 분류할 수 있다.

## 양식화 데모
사장님용 질문 입력 → 표준 JSON → 모바일 랜딩페이지 미리보기로 이어지는 양식화 데모를 생성했다.

```text
/home/ubuntu/crewup-work/landing-samples/data-driven-landing-template/formalized-nail-booking-template/index.html
```

이 데모는 17단계를 `Hero`, `Problem`, `Solution`, `Proof`, `Offer`, `Action` 6개 블록으로 압축한다. 고객 요청 시 추가 가능한 내용도 먼저 `예약 망설임`, `진행 방식`, `신뢰 증거`, `안심 오퍼`, `예약 행동` 같은 추가 압축 블록으로 보여주고, 더 세밀한 요청이 있을 때만 17단계 개별 섹션을 작성 양식과 미리보기에 끼워 넣을 수 있게 한다.

## 관련
- [[mobile-promo-page-builder]]
- [[data-driven-template-market]]
- [[industry-template-database]]
