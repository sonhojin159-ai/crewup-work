# AWS EC2 작업환경 세팅 가이드

이 문서는 CrewUp 서비스를 AWS로 이전하기 위한 문서가 아닙니다.
목적은 노트북을 계속 켜두지 않고도 Hermes/에이전트/CLI 작업을 지속할 수 있는 원격 작업 컴퓨터를 만드는 것입니다.

## 추천 구성

- EC2 Ubuntu 22.04 또는 24.04
- 처음에는 `t3.small` 또는 `t3.medium`
- 디스크 30~50GB gp3
- SSH key 로그인만 허용
- VS Code Remote SSH로 접속
- tmux로 장시간 agent 세션 유지
- CrewUp 배포는 기존 Netlify + Supabase 유지

## 비용 안전장치

AWS에서 먼저 설정하세요.

1. Billing → Budgets → 월 예산 알림 생성
2. 예상 비용 알림 이메일 등록
3. EC2를 쓰지 않을 때 stop하는 습관 유지
4. Elastic IP를 만들었다면 미연결 상태로 방치하지 않기

## Security Group 권장

Inbound:

- SSH 22: 내 IP만 허용
- 4177 등 개발 서버 포트: 기본적으로 열지 않음

개발 서버 확인은 SSH 터널을 권장합니다.

```bash
ssh -L 4177:localhost:4177 ubuntu@EC2_PUBLIC_IP
```

## EC2 최초 접속 후 실행

```bash
sudo apt-get update
sudo apt-get install -y git curl ca-certificates build-essential tmux unzip jq

git clone https://github.com/sonhojin159-ai/crewup-work.git ~/crewup-work
cd ~/crewup-work
chmod +x scripts/bootstrap_remote_dev.sh
./scripts/bootstrap_remote_dev.sh
```

## VS Code Remote SSH

로컬 노트북의 VS Code에서:

1. Remote - SSH 확장 설치
2. `Connect to Host...`
3. `ubuntu@EC2_PUBLIC_IP` 접속
4. `~/crewup-work` 폴더 열기

## tmux 기본 명령

새 세션:

```bash
tmux new -s hermes
```

세션 분리:

`Ctrl+b` → `d`

다시 접속:

```bash
tmux attach -t hermes
```

세션 목록:

```bash
tmux ls
```

## Hermes 실행 예시

```bash
cd ~/crewup-work
hermes
```

장시간 작업/agent는 tmux 안에서 실행하세요.

## Obsidian Vault 운영

Vault 경로:

`~/crewup-work/Obsidian_Vault`

서버에서 자동 저장된 노트는 git commit/push 후 노트북에서 pull해서 Obsidian 앱으로 볼 수 있습니다.

## 주의

- 실제 `.env`와 API key는 절대 git commit하지 않습니다.
- Claude/Codex/Grok/OpenAI 등 CLI 로그인은 서버마다 다시 해야 합니다.
- EC2를 public internet에 열어둔 상태에서 Hermes를 무제한/yolo로 운영하지 않습니다.
- 자동화는 처음에는 짧은 cron/리서치부터 시작하고, 배포 권한이 있는 작업은 수동 승인으로 유지합니다.
