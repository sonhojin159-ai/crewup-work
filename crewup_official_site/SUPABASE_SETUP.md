# CrewUp — Supabase 연동 설정 가이드

## 1. Supabase 프로젝트 만들기

1. [https://supabase.com](https://supabase.com) → 로그인 → **New Project**
2. 프로젝트 이름: `crewup` (원하는 이름 가능)
3. 데이터베이스 비밀번호 설정 후 **Create new project** 클릭
4. 프로젝트 대시보드 → **Settings → API** 에서 다음 두 값 확인:
   - **Project URL** (예: `https://abcdefgh.supabase.co`)
   - **anon public key** (긴 JWT 문자열)

## 2. config.js 만들기

### 로컬 개발

```bash
# crewup_official_site/ 디렉터리에서 실행
cp config.example.js config.js
```

`config.js` 를 열고 플레이스홀더를 실제 값으로 교체하세요:

```js
window.CREWUP_CONFIG = {
  SUPABASE_URL: "https://abcdefgh.supabase.co",   // ← Project URL
  SUPABASE_ANON_KEY: "eyJhbG...NiIs..."    // ← anon public key
};
```

### Netlify 배포

이 저장소의 `netlify.toml`은 빌드 시 Netlify 환경변수로 `crewup_official_site/config.js`를 생성합니다.
Netlify 대시보드 → **Site configuration → Environment variables**에 아래 값을 추가하세요.

- `SUPABASE_URL`: Supabase Project URL
- `SUPABASE_ANON_KEY`: Supabase anon public key

환경변수를 추가/수정한 뒤에는 **Deploys → Trigger deploy → Deploy site**로 재배포해야 합니다.
배포된 사이트에서 아래 URL이 200으로 열리고 실제 값이 보이면 Supabase 초기화 준비가 된 것입니다.

```text
https://배포도메인/config.js
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

### Storage RLS / policy 주의

`crew-files`는 비공개 버킷으로 유지해야 하며, 파일 접근 권한은 공개 URL이 아니라 Supabase Storage policy로 제어해야 합니다.

- `crew_files` 테이블은 파일 메타데이터만 저장합니다. 실제 파일 권한은 `storage.objects` policy에서 별도로 관리됩니다.
- MVP 단계에서는 버킷만 먼저 만들고, 실제 파일 업로드 기능을 연결하기 전에 `storage.objects`의 업로드/조회/삭제 policy를 점검하세요.
- 권장 경로 규칙: `crew_id/파일명` 형태로 업로드합니다. 예: `9f4c.../proposal.pdf`
- 권장 방향:
  - 업로드: 로그인한 사용자가 자신이 속한 크루 경로에만 업로드
  - 조회: 해당 크루 멤버만 다운로드/조회
  - 삭제: 업로더 또는 크루장만 삭제
- service_role key를 브라우저 config에 넣어 Storage 권한 문제를 우회하지 마세요.

#### 참고용 `storage.objects` policy 예시

아래 SQL은 `crew-files` 버킷의 파일 경로 첫 번째 폴더명을 `crew_id`로 쓰는 경우의 예시입니다. 실제 업로드 로직을 연결할 때 경로 규칙과 함께 재확인하세요.

```sql
-- crew-files bucket objects are readable only by crew members.
DROP POLICY IF EXISTS "crew-files: members can read objects" ON storage.objects;
CREATE POLICY "crew-files: members can read objects"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'crew-files'
    AND public.is_crew_member((storage.foldername(name))[1]::uuid)
  );

-- Crew members can upload into their own crew folder only.
DROP POLICY IF EXISTS "crew-files: members can upload objects" ON storage.objects;
CREATE POLICY "crew-files: members can upload objects"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'crew-files'
    AND auth.uid() IS NOT NULL
    AND public.is_crew_member((storage.foldername(name))[1]::uuid)
  );

-- Uploader or crew owner can delete the object.
DROP POLICY IF EXISTS "crew-files: uploader or owner can delete objects" ON storage.objects;
CREATE POLICY "crew-files: uploader or owner can delete objects"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'crew-files'
    AND (
      owner = auth.uid()
      OR public.is_crew_owner((storage.foldername(name))[1]::uuid)
    )
  );
```

> `storage.foldername(name)[1]`이 UUID로 변환되지 않는 경로가 업로드되면 policy 평가 중 오류가 날 수 있습니다. 업로드 코드에서 반드시 `crew_id/...` 경로만 만들도록 제한하세요.

## 5. Auth 설정 — Redirect URL

대시보드 → **Authentication → URL Configuration**

`crewup_official_site/` 디렉터리에서 서버를 띄우는 현재 실행 방식 기준으로,
**Site URL** 및 **Redirect URLs** 에 로컬 개발 주소를 추가하세요:

```
http://localhost:4177/
http://localhost:4177/app.html
```

Netlify/커스텀 도메인 배포 후에는 실제 배포 주소도 반드시 추가하세요. Magic Link는 `app.html`로 돌아와야 하므로 최소 아래 형식이 필요합니다.

```text
https://배포도메인/
https://배포도메인/app.html
https://커스텀도메인/
https://커스텀도메인/app.html
```

상위 폴더(`/workspace/MA`)에서 서버를 띄우는 경우에만
`http://localhost:4177/crewup_official_site/app.html` 형식의 URL을 별도로 추가합니다.

**중요**: Magic Link 발송 시 앱은 현재 페이지의 `origin + pathname`을 `emailRedirectTo`로 보냅니다. 배포 사이트에서 로그인 버튼을 누르면 보통 `https://배포도메인/app.html`이 Redirect URL로 사용됩니다. Supabase에 이 URL이 등록되어 있지 않으면 링크 클릭 후 로그인 세션이 잡히지 않거나 허용되지 않은 redirect 오류가 발생합니다.

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
2. 이메일 입력 후 **로그인 링크 받기** 클릭
3. 입력한 이메일로 Magic Link 메일 도착
4. 메일의 링크 클릭 → `app.html` 로 리다이렉트 + 자동 로그인
5. 이후 세션 유지 (브라우저 탭 닫아도 유지됨)

## 8. config.js 없을 때 동작

`config.js` 가 없거나 플레이스홀더 상태이면:
- Supabase 초기화를 건너뜁니다.
- `index.html` 의 공개 크루 목록은 DB에서 불러오지 못하고 빈 상태 안내가 표시될 수 있습니다.
- `app.html` 은 실제 Magic Link 메일을 보낼 수 없습니다.
- 배포 환경에서 이 상태가 나오면 Netlify 환경변수와 `/config.js` 생성 여부를 먼저 확인하세요.

## 9. 문제 해결

| 증상 | 해결 |
|---|---|
| Magic Link 메일이 안 옴 | Supabase 대시보드 → Authentication → Logs 확인 |
| 로그인 후 리다이렉트가 안 됨 | Redirect URL 설정 확인 (5번 항목) |
| RLS 오류 (42501) | 스키마 SQL을 다시 실행했는지 확인 |
| Storage 업로드 실패 | `crew-files` 버킷이 존재하는지 확인 |
| `config.js` 로드 실패 | 파일이 `crewup_official_site/config.js` 에 있는지 확인 |
