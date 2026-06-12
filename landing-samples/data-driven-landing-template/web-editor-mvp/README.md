# 웹 편집기 MVP

소상공인용 모바일 홍보페이지 양식 마켓/빌더 MVP 데모입니다.

## 파일

- `index.html`: 단일 파일 웹 편집기 데모
- `screenshots/editor-lookbook.png`: 크몽 상세페이지용 룩북형 캡처
- `screenshots/editor-poster.png`: 크몽 상세페이지용 포스터형 캡처
- `screenshots/editor-instagram.png`: 크몽 상세페이지용 인스타형 캡처
- `screenshots/editor-calendar.png`: 크몽 상세페이지용 예약 캘린더형 캡처

## 구현된 기능

- 왼쪽 입력 패널
  - 매장명
  - 메인 제목
  - 상단 짧은 문구
  - 설명문
  - 품목명 / 가격 / 설명
  - 이벤트명 / 혜택
  - 대표 이미지 URL
- 오른쪽 390px 모바일 미리보기
- 상단 양식 선택 버튼
  - lookbook
  - poster
  - instagram
  - calendar
- 입력값 변경 시 즉시 미리보기 반영
- 샘플/시안용 워터마크 표시
- 현재 선택 양식 HTML 다운로드 버튼 구현
- `?template=poster` 같은 URL 파라미터로 캡처용 초기 양식 선택 가능

## 로컬 확인

```bash
cd /home/ubuntu/crewup-work/landing-samples/data-driven-landing-template/web-editor-mvp
python3 -m http.server 8765 --bind 127.0.0.1
```

브라우저에서:

```text
http://127.0.0.1:8765/index.html
http://127.0.0.1:8765/index.html?template=poster
```

## 스크린샷 생성 명령

```bash
mkdir -p screenshots
for t in lookbook poster instagram calendar; do
  chromium --headless --no-sandbox --disable-gpu --hide-scrollbars --window-size=1400,1100 \
    --screenshot="screenshots/editor-${t}.png" \
    "http://127.0.0.1:8765/index.html?template=${t}"
done
```

## 크몽 상세페이지 활용 방향

- “랜딩페이지 제작”이 아니라 “사진과 가격표만 넣으면 완성되는 인스타 프로필용 모바일 안내페이지”로 보여준다.
- 왼쪽 입력 패널 + 오른쪽 폰 미리보기 캡처를 넣어 “양식형/저가형/수정 쉬움”을 직관적으로 설명한다.
- 기본형은 19,000~29,000원, 자체 자동 판매는 9,900원부터 테스트한다.
