# CrewUp 원격 작업환경 복구 가이드

이 문서는 노트북을 교체하거나 원격 서버(AWS EC2/VPS)로 작업환경을 옮길 때 CrewUp 작업환경을 재현하기 위한 기준 문서입니다.

## 현재 보존되는 것

GitHub 원격 저장소:

`https://github.com/sonhojin159-ai/crewup-work.git`

Git에 커밋되어 있으면 새 PC/서버에서 복구 가능합니다.

- CrewUp 정적 사이트 코드
- Netlify 설정
- Supabase SQL 스키마/스토리지 정책 파일
- Hermes 작업 지시서/완료 보고서 문서
- Obsidian Vault 기본 구조와 노트
- 원격 작업환경 세팅 문서/스크립트

## Git에 저장하면 안 되는 것

- 실제 `.env`
- `crewup_official_site/config.js`
- Supabase service_role key
- DB password
- Netlify token
- GitHub token
- 모델/API key
- Claude/Codex/Grok/OpenAI 로그인 토큰

실제 비밀값은 1Password, Bitwarden, iCloud Keychain, Windows Credential Manager, AWS Secrets Manager 등 별도 안전한 장소에 보관합니다.

## 새 원격 서버에서 복구 순서

### 1. 서버 준비

권장 OS:

- Ubuntu 22.04 LTS 또는 24.04 LTS

권장 접속:

- VS Code Remote SSH
- 또는 터미널 SSH + tmux

### 2. 기본 패키지 설치

```bash
sudo apt-get update
sudo apt-get install -y git curl ca-certificates build-essential tmux unzip jq
```

### 3. 저장소 clone

```bash
git clone https://github.com/sonhojin159-ai/crewup-work.git ~/crewup-work
cd ~/crewup-work
```

### 4. bootstrap 실행

```bash
chmod +x scripts/bootstrap_remote_dev.sh
./scripts/bootstrap_remote_dev.sh
```

### 5. 환경변수 작성

```bash
cp .env.example .env
nano .env
```

필수 입력:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Hermes 내부 환경에도 Obsidian Vault 경로가 필요하면 다음 값을 `~/.hermes/.env`에 추가합니다.

```bash
OBSIDIAN_VAULT_PATH=$HOME/crewup-work/Obsidian_Vault
```

### 6. CrewUp 로컬 미리보기

```bash
cd ~/crewup-work/crewup_official_site
cp config.example.js config.js
# config.js에 Supabase URL/anon key 입력
python3 -m http.server 4177
```

브라우저에서:

`http://서버IP:4177`

보안상 EC2 Security Group에서 4177 포트를 전체 공개하지 않는 것을 권장합니다. 필요하면 SSH 터널을 사용합니다.

```bash
ssh -L 4177:localhost:4177 ubuntu@서버IP
```

그 후 로컬 브라우저에서:

`http://localhost:4177`

### 7. Hermes 설치/설정

Hermes가 설치되어 있지 않다면:

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
hermes setup
```

설치 후:

```bash
hermes doctor
hermes tools list
```

필요한 toolset:

- file
- terminal
- skills
- session_search
- cronjob
- delegation
- web/browser는 필요 시

### 8. 모델/CLI 로그인

각 모델 CLI는 새 서버에서 다시 로그인해야 합니다.

- Claude Code / Claude CLI
- Codex CLI
- Anti-Gravity CLI
- Netlify CLI
- Supabase CLI
- GitHub CLI

구독 자체가 자동으로 서버에 복사되지는 않습니다. 각 CLI의 인증 절차를 새 환경에서 다시 진행합니다.

## 노트북과 원격 서버 역할 분리

노트북:

- VS Code Remote SSH 접속
- Obsidian 열람/수정
- 최종 승인/기획

원격 서버:

- Hermes 실행
- Claude/Codex/Anti-Gravity CLI 실행
- cron/agent 장기 실행
- tmux 세션 유지
- GitHub push/pull

## 작업 전후 규칙

작업 시작:

```bash
git pull --rebase
```

작업 완료:

```bash
git status
git add 변경파일
git commit -m "type: message"
git push
```

노트북 교체/서버 재생성 시 GitHub에 push되지 않은 내용은 복구하기 어렵습니다.
