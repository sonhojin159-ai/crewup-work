# CrewUp — Supabase 연동 설정 가이드

## 1. Supabase 프로젝트 만들기

1. [https://supabase.com](https://supabase.com) → 로그인 → **New Project**
2. 프로젝트 이름: `crewup` (원하는 이름 가능)
3. 데이터베이스 비밀번호 설정 후 **Create new project** 클릭
4. 프로젝트 대시보드 → **Settings → API** 에서 다음 두 값 확인:
   - **Project URL** (예: `https://abcdefgh.supabase.co`)
   - **anon public key** (긴 JWT 문자열)

## 2. config.js 만들기

```bash
# crewup_official_site/ 디렉터리에서 실행
cp config.example.js config.js
```

`config.js` 를 열고 플레이스홀더를 실제 값으로 교체하세요:

```js
window.CREWUP_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",   // ← Project URL
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIs..."    // ← anon public key
};
```

> **주의**: `config.js` 는 `.gitignore` 에 포함되어 있어 git에 커밋되지 않습니다.  
> `service_role` 키는 절대 사용하지 마세요. `anon` 키만 사용합니다.

## 3. 데이터베이스 스키마 실행

Supabase 대시보드 → **SQL Editor** → **New query**

`supabase_schema.sql` 파일 전체를 붙여넣고 **Run** 클릭.

`supabase_schema.sql` 은 개발 중 반복 실행할 수 있도록 각 RLS policy를 다시 만들기 전에
`DROP POLICY IF EXISTS` 를 먼저 실행합니다. 기존 데이터를 지우지는 않지만,
정책을 수동으로 수정해 둔 경우 파일의 정의로 덮어씁니다.

생성되는 테이블:

| 테이블 | 설명 |
|---|---|
| `profiles` | auth.users 자동 연동, 표시 이름·아바타 |
| `crews` | 크루 정보 (이름, 설명, 카테고리, 공개 여부) |
| `crew_members` | 크루 멤버 + 권한 (파일/사진/영상) |
| `join_requests` | 가입 신청 (pending / approved / rejected) |
| `crew_messages` | 크루 채팅 메시지 |
| `crew_notes` | 크루 노트 |
| `crew_links` | 크루 공유 링크 |
| `crew_files` | 업로드 파일 메타데이터 |

## 4. Storage 버킷 만들기

대시보드 → **Storage** → **New bucket**

- **Name**: `crew-files`
- **Public bucket**: OFF (비공개)
- **File size limit**: 50 MB (권장)
- **Allowed MIME types**: 비워두면 모든 타입 허용

> SQL로는 버킷을 만들 수 없습니다. 반드시 대시보드 또는 Management API를 사용하세요.

## 5. Auth 설정 — Redirect URL

대시보드 → **Authentication → URL Configuration**

`crewup_official_site/` 디렉터리에서 서버를 띄우는 현재 실행 방식 기준으로,
**Site URL** 및 **Redirect URLs** 에 로컬 개발 주소를 추가하세요:

```
http://localhost:4177/
http://localhost:4177/app.html
```

상위 폴더(`/workspace/MA`)에서 서버를 띄우는 경우에만
`http://localhost:4177/crewup_official_site/app.html` 형식의 URL을 별도로 추가합니다.

프로덕션 배포 시 실제 도메인도 추가해야 합니다.

**Email 확인(Confirm email)** 옵션:  
개발 중에는 **Authentication → Settings → Disable email confirmations** 체크를 해제해도 되지만,  
프로덕션에서는 반드시 활성화하세요.

## 6. 로컬에서 실행하기

```bash
cd /workspace/MA/crewup_official_site
python3 -m http.server 4177
```

브라우저에서 `http://localhost:4177/` 열기.

> `file://` 프로토콜로 직접 열면 Magic Link 인증 후 리다이렉트가 동작하지 않습니다.  
> 반드시 HTTP 서버를 통해 접근하세요.

## 7. Magic Link 로그인 흐름

1. `app.html` 접근 → 로그인 화면 표시
2. 이메일 입력 후 **메일 링크로 입장하기** 클릭
3. 입력한 이메일로 Magic Link 메일 도착
4. 메일의 링크 클릭 → `app.html` 로 리다이렉트 + 자동 로그인
5. 이후 세션 유지 (브라우저 탭 닫아도 유지됨)

## 8. config.js 없을 때 동작

`config.js` 가 없거나 플레이스홀더 상태이면:
- Supabase 초기화를 건너뜀
- `index.html` 의 크루 목록은 정적 카드로 표시
- `app.html` 은 오프라인 확인용 입장 버튼으로 작업실 화면 확인 가능
- Magic Link 전송, 실제 공개 크루 로딩, 참여 신청 저장은 비활성화

## 9. 문제 해결

| 증상 | 해결 |
|---|---|
| Magic Link 메일이 안 옴 | Supabase 대시보드 → Authentication → Logs 확인 |
| 로그인 후 리다이렉트가 안 됨 | Redirect URL 설정 확인 (5번 항목) |
| RLS 오류 (42501) | 스키마 SQL을 다시 실행했는지 확인 |
| Storage 업로드 실패 | `crew-files` 버킷이 존재하는지 확인 |
| `config.js` 로드 실패 | 파일이 `crewup_official_site/config.js` 에 있는지 확인 |
