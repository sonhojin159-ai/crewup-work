# [Context]

프로젝트명: Crew Up
현재 작업 폴더: `/workspace/MA/crewup_official_site`
Windows 실제 경로: `C:\Users\sonho\Desktop\MA\crewup_official_site`

현재 상태:
- 정식 랜딩 후보: `/workspace/MA/crewup_official_site/index.html`
- 작업실 앱 후보: `/workspace/MA/crewup_official_site/Crew App.html`
- 두 파일은 정적 HTML/CSS/JS 기반으로 동작한다.
- 현재 로그인/작업실/공유함/노트/링크/멤버 관리/크루 설정은 실제 DB 없이 데모 상태다.
- 최근 검수에서 다음 항목은 정리 완료됨:
  - 깨진 `Crew Up.html` 링크 제거
  - `프로토타입`, `데모`, `실험실`, `실험하고` 등 공개 부적합 문구 제거
  - `포트폴리오` 버튼명을 `크루 상세보기`로 정리
  - aria-label 없는 빈 버튼 제거
  - JS 문법 체크 통과

이번 단계 목표:
- 현재 정적 결과물을 Supabase 기반 MVP로 전환한다.
- 단, 실제 Supabase 프로젝트 키/URL은 사용자가 나중에 넣을 수 있게 placeholder/example 방식으로 처리한다.
- 프로덕션 배포는 하지 않는다.
- git commit은 하지 않는다. 작업 완료 후 Hermes가 검토하고 commit한다.

---

## [New Task]

Crew Up의 다음 개발 단계는 **Supabase Auth + Database + Storage MVP 연결**이다.

이번 작업은 단순 UI 수정이 아니라, 현재 정적 HTML 결과물을 실제 데이터 기반으로 전환하기 위한 기반 작업이다.

반드시 아래 순서대로 진행하라.

---

# 1. 파일 구조 정리

## 1-1. 앱 파일명 변경

현재 앱 파일:

```txt
/workspace/MA/crewup_official_site/Crew App.html
```

공백이 있는 파일명은 개발/배포/링크 관리에 불편하므로 다음으로 변경한다.

```txt
/workspace/MA/crewup_official_site/app.html
```

## 1-2. 랜딩 링크 수정

`index.html` 안의 모든 앱 진입 링크를 다음 기준으로 수정한다.

```txt
Crew App.html → app.html
```

대상 예시:
- 로그인
- 시작하기
- 모바일 drawer 로그인
- 기타 앱 진입 CTA

검증:
- `index.html`에서 로그인/시작하기 클릭 시 `app.html`로 이동해야 한다.
- 더 이상 `Crew App.html`, `Crew Up.html` 링크가 남아 있으면 안 된다.

---

# 2. Supabase 설정 파일 추가

정적 HTML에서 Supabase를 연결할 수 있도록 설정 파일을 분리한다.

새 파일을 만든다.

```txt
/workspace/MA/crewup_official_site/config.example.js
```

내용 예시:

```js
window.CREWUP_CONFIG = {
  SUPABASE_URL: "https://YOUR_PROJECT_ID.supabase.co",
  SUPABASE_ANON_KEY: "YOUR_SUPABASE_ANON_KEY"
};
```

그리고 실제 로컬 사용용 파일은 다음 이름으로 둘 수 있게 안내한다.

```txt
/workspace/MA/crewup_official_site/config.js
```

주의:
- `config.js`는 실제 키가 들어갈 수 있으므로 `.gitignore`에 추가한다.
- `config.example.js`만 커밋 대상이다.
- 이번 작업에서 실제 Supabase 키를 임의로 넣지 않는다.

필요 시 `/workspace/MA/.gitignore`에 다음을 추가한다.

```gitignore
crewup_official_site/config.js
```

---

# 3. Supabase 클라이언트 연결

`app.html`에서 Supabase JS를 사용할 수 있게 연결한다.

권장 방식:
- CDN 사용 가능
- 단, CDN 사용 이유를 완료 보고서에 기록한다.

예시:

```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="config.js"></script>
```

초기화 로직은 안전하게 작성한다.

요구사항:
- `window.CREWUP_CONFIG`가 없거나 placeholder 상태이면 앱이 깨지지 않아야 한다.
- 이 경우 “Supabase 설정이 필요합니다” 안내를 표시하고, 기존 데모 화면은 최소한 확인 가능하게 유지한다.
- 실제 키가 있으면 Supabase 연결을 시도한다.
- 콘솔에 anon key 전체를 출력하지 않는다.

---

# 4. Database schema SQL 작성

Supabase SQL Editor에서 실행할 수 있는 schema 파일을 만든다.

새 파일:

```txt
/workspace/MA/crewup_official_site/supabase_schema.sql
```

최소 테이블:

## 4-1. profiles

목적:
- Supabase auth user와 연결되는 사용자 프로필

필드 예시:
- id uuid primary key references auth.users(id) on delete cascade
- email text
- display_name text
- avatar_url text
- bio text
- created_at timestamptz default now()
- updated_at timestamptz default now()

## 4-2. crews

목적:
- 공개 크루 목록과 작업실의 기본 단위

필드 예시:
- id uuid primary key default gen_random_uuid()
- name text not null
- slug text unique
- category text not null
- description text
- purpose text
- rhythm text
- leader_id uuid references profiles(id)
- plan text default 'free' check (plan in ('free', 'plus', 'pro'))
- visibility text default 'public' check (visibility in ('public', 'private'))
- recruiting_status text default 'open' check (recruiting_status in ('open', 'closing', 'closed'))
- max_members int default 10
- storage_limit_mb int default 1024
- created_at timestamptz default now()
- updated_at timestamptz default now()

## 4-3. crew_members

목적:
- 크루 멤버와 역할 관리

필드 예시:
- id uuid primary key default gen_random_uuid()
- crew_id uuid references crews(id) on delete cascade
- user_id uuid references profiles(id) on delete cascade
- role text default 'member' check (role in ('leader', 'admin', 'member'))
- can_upload_docs boolean default true
- can_upload_images boolean default false
- can_upload_videos boolean default false
- joined_at timestamptz default now()
- unique(crew_id, user_id)

## 4-4. join_requests

목적:
- 크루 참여 신청

필드 예시:
- id uuid primary key default gen_random_uuid()
- crew_id uuid references crews(id) on delete cascade
- user_id uuid references profiles(id) on delete cascade
- message text
- status text default 'pending' check (status in ('pending', 'accepted', 'rejected'))
- created_at timestamptz default now()
- updated_at timestamptz default now()
- unique(crew_id, user_id)

## 4-5. crew_messages

목적:
- 작업실 채팅/공지/활동 로그의 최소 기반

필드 예시:
- id uuid primary key default gen_random_uuid()
- crew_id uuid references crews(id) on delete cascade
- user_id uuid references profiles(id) on delete set null
- type text default 'chat' check (type in ('chat', 'notice', 'activity'))
- body text not null
- created_at timestamptz default now()

## 4-6. crew_notes

목적:
- 크루 노트

필드 예시:
- id uuid primary key default gen_random_uuid()
- crew_id uuid references crews(id) on delete cascade
- author_id uuid references profiles(id) on delete set null
- title text not null
- body text
- created_at timestamptz default now()
- updated_at timestamptz default now()

## 4-7. crew_links

목적:
- 크루 링크 허브

필드 예시:
- id uuid primary key default gen_random_uuid()
- crew_id uuid references crews(id) on delete cascade
- created_by uuid references profiles(id) on delete set null
- title text not null
- url text not null
- description text
- created_at timestamptz default now()

## 4-8. crew_files

목적:
- Supabase Storage 파일 메타데이터

필드 예시:
- id uuid primary key default gen_random_uuid()
- crew_id uuid references crews(id) on delete cascade
- uploaded_by uuid references profiles(id) on delete set null
- bucket text default 'crew-files'
- path text not null
- name text not null
- file_type text check (file_type in ('doc', 'image', 'video', 'other'))
- size_bytes bigint default 0
- created_at timestamptz default now()

---

# 5. RLS Policy SQL 작성

같은 `supabase_schema.sql`에 RLS enable 및 policy도 포함한다.

필수 원칙:

1. 공개 크루 목록
- `crews.visibility = 'public'`인 크루는 누구나 읽을 수 있다.

2. 작업실 내부 데이터
- `crew_messages`, `crew_notes`, `crew_links`, `crew_files`는 해당 크루 멤버만 읽을 수 있다.

3. 멤버 관리
- `crew_members`는 같은 크루 멤버가 읽을 수 있다.
- insert/update/delete는 leader/admin만 가능하게 한다.

4. 참여 신청
- 로그인 사용자는 본인의 신청을 생성/조회할 수 있다.
- 크루 leader/admin은 해당 크루 신청을 조회하고 상태 변경할 수 있다.

5. Storage 메타데이터
- 파일 메타데이터는 크루 멤버만 읽는다.
- 업로드는 crew_members의 권한 필드에 따라 허용한다.

주의:
- RLS가 너무 느슨하면 안 된다.
- “모든 로그인 사용자 전체 읽기 허용” 같은 정책은 피한다.
- 복잡한 정책은 helper function을 만들어도 된다.

---

# 6. Storage bucket 안내 SQL/문서 작성

Supabase Storage bucket은 SQL만으로 완전히 처리하기 애매할 수 있으므로 별도 안내 문서를 만든다.

새 파일:

```txt
/workspace/MA/crewup_official_site/SUPABASE_SETUP.md
```

포함 내용:
- Supabase 프로젝트 생성
- `supabase_schema.sql` 실행 방법
- Storage bucket 생성
  - bucket name: `crew-files`
  - public: false
- `config.example.js`를 복사해서 `config.js` 만드는 방법
- `SUPABASE_URL`, `SUPABASE_ANON_KEY` 넣는 위치
- 로컬 확인 방법

---

# 7. Auth 연결

`app.html`의 로그인 화면을 Supabase Auth와 연결한다.

현재 UI는 magic link 스타일이므로 우선 Supabase magic link 기반으로 구현한다.

요구사항:
- 이메일 입력 후 `signInWithOtp` 호출
- 성공 시 “메일함을 확인하세요” 화면 표시
- 실패 시 사용자에게 에러 메시지 표시
- 이미 세션이 있으면 바로 작업실 화면 표시
- 로그아웃 기능 추가 또는 기존 사용자 메뉴에서 로그아웃 가능하게 처리
- config가 없으면 Supabase 호출 대신 기존 확인용 입장 플로우가 깨지지 않게 유지

주의:
- 실제 이메일 리디렉션 URL은 현재 정적 파일 구조상 배포 주소가 필요할 수 있다.
- `SUPABASE_SETUP.md`에 redirect URL 설정 안내를 적는다.

---

# 8. 데이터 연동 최소 구현

이번 MVP에서는 완전한 CRUD를 모두 만들 필요는 없다.
현재 UI를 망치지 않고, Supabase 데이터가 있으면 가져오고 없으면 안전한 빈 상태/샘플 상태를 보여주는 방식으로 구현한다.

## 8-1. 랜딩 `index.html`

가능하면 다음을 Supabase에서 로드한다.
- 인기 크루
- 전체 크루 목록

요구사항:
- config가 없으면 현재 하드코딩 예시 카드 유지
- config가 있으면 `crews`에서 public crew를 읽어서 표시
- 데이터가 비어 있으면 “아직 공개된 크루가 없어요” 같은 빈 상태 표시
- JS 에러로 랜딩 전체가 깨지면 안 된다.

## 8-2. 앱 `app.html`

로그인 후:
- 현재 사용자의 `profiles` 확인/생성
- 사용자가 속한 첫 번째 crew 로드
- crew가 없으면 “아직 참여 중인 크루가 없어요” 빈 상태 표시
- crew가 있으면 다음을 로드:
  - crew 기본 정보
  - crew_members
  - crew_messages
  - crew_notes
  - crew_links
  - crew_files

요구사항:
- 데이터가 없을 때도 화면이 깨지면 안 된다.
- 기존 목업 데이터는 fallback으로만 사용한다.
- Supabase 연결 성공 시 가능한 실제 데이터 우선 표시한다.

---

# 9. 참여 신청 연결

`index.html`의 참여 신청 모달을 Supabase와 연결한다.

요구사항:
- 로그인하지 않은 사용자가 참여 신청을 누르면 app/login으로 유도하거나 로그인 필요 메시지 표시
- 로그인 세션이 있으면 `join_requests`에 insert
- 이미 신청한 크루이면 중복 신청 안내
- 성공 시 “참여 신청이 전달됐어요” 메시지 표시
- config가 없으면 현재처럼 확인용 메시지/fallback 유지

---

# 10. 파일 업로드는 이번 단계에서 최소 처리

이번 단계에서 실제 Storage 업로드까지 완성하면 좋지만, 시간이 크면 다음 단계로 미뤄도 된다.

최소 요구:
- `crew_files` 메타데이터 구조 준비
- Storage bucket 안내 작성
- 업로드 버튼 클릭 시 “파일 업로드는 준비 중이에요” 또는 Supabase 설정 후 사용 가능하다는 안내 유지

가능하면 구현:
- `crew-files` bucket에 파일 업로드
- 업로드 후 `crew_files` insert
- 멤버별 업로드 권한 체크

단, 무리해서 복잡하게 만들지 말고 MVP 안정성을 우선한다.

---

# 11. 검증

작업 후 반드시 수행한다.

## 11-1. 파일 존재 확인

확인할 파일:

```txt
/workspace/MA/crewup_official_site/index.html
/workspace/MA/crewup_official_site/app.html
/workspace/MA/crewup_official_site/config.example.js
/workspace/MA/crewup_official_site/supabase_schema.sql
/workspace/MA/crewup_official_site/SUPABASE_SETUP.md
```

`Crew App.html`은 rename 완료 후 남아 있지 않아야 한다.

## 11-2. 링크 검사

다음 문자열이 남아 있으면 안 된다.

```txt
Crew App.html
Crew Up.html
```

## 11-3. 공개 부적합 문구 검사

다음 문구가 사용자 화면에 노출되면 안 된다.

```txt
프로토타입
데모
실험실
검증용
컨테이너
락인
소규모
small crew
```

HTML 태그 `<small>`은 사용 가능하지만, 공개 문구로 small/small crew 의미가 노출되면 안 된다.

## 11-4. JS 문법 체크

HTML 내부 script를 추출하거나 적절한 방식으로 JS 문법을 점검한다.

## 11-5. 브라우저 검증

로컬 서버로 확인한다.

```bash
cd /workspace/MA/crewup_official_site
python3 -m http.server 4177
```

확인 URL:

```txt
http://127.0.0.1:4177/index.html
http://127.0.0.1:4177/app.html
```

확인 항목:
- 랜딩 로딩 정상
- 로그인/시작하기가 `app.html`로 이동
- `app.html` 로딩 정상
- config가 없을 때도 화면이 깨지지 않음
- console error 없음
- 로그인 입력 플로우가 깨지지 않음
- 작업실 fallback 화면 또는 Supabase 연결 안내가 자연스럽게 표시됨

---

# 12. 금지사항

- 프로덕션 배포 금지
- 실제 Supabase secret/service role key 사용 금지
- anon key placeholder 외 실제 키를 임의로 작성 금지
- git commit 금지
- 기존 디자인을 전면 재작성하지 말 것
- 이번 단계에서 결제/네이티브 앱/실시간 협업 문서/화상회의 기능을 만들지 말 것
- 불필요한 대형 프레임워크로 전환하지 말 것

---

## [Completed]

- Crew Up 정식 랜딩 후보 생성 완료
- Crew Up 작업실 앱 후보 생성 완료
- `index.html`, `Crew App.html` 기능 검수 완료
- 공개 부적합 문구 1차 정리 완료
- 깨진 링크 1차 정리 완료
- 접근성 빈 버튼 aria-label 1차 정리 완료
- 현재 결과물은 git commit `9f76c15 Add Crew Up official site prototype`로 보존됨
- 불필요한 임시 파일 정리 완료

---

## [Agent Report Template]

작업 완료 후 아래 파일에 보고서를 작성한다.

```txt
/workspace/MA/main_done.md
```

보고서 형식:

```md
# Crew Up Supabase MVP 연결 작업 완료 보고서

## 작업 상태
- 성공/실패:

## 생성/수정된 파일 목록
-

## 핵심 구현 요약
- 파일 구조 변경:
- Supabase 설정 방식:
- Auth 연결 방식:
- DB schema 요약:
- RLS policy 요약:
- Storage 준비 상태:
- 랜딩 데이터 연동 상태:
- 앱 데이터 연동 상태:

## 사용자가 직접 설정해야 하는 항목
- Supabase 프로젝트 URL:
- Supabase anon key:
- Supabase Auth redirect URL:
- Storage bucket:
- SQL 실행 여부:

## 검증 결과
- JS 문법 체크:
- 로컬 서버 확인:
- 브라우저 콘솔 에러:
- 링크 검사:
- 공개 부적합 문구 검사:

## 구현하지 않은 항목 / 다음 단계
-

## 에러 및 특이사항
-
```

보고서는 코드 전문이 아니라 핵심 요약과 검증 결과 중심으로 작성한다.
