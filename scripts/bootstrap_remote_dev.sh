#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "[CrewUp] remote dev bootstrap start: $PROJECT_DIR"

if command -v apt-get >/dev/null 2>&1; then
  echo "[CrewUp] installing base packages"
  sudo apt-get update
  sudo apt-get install -y \
    git curl ca-certificates build-essential tmux unzip jq \
    python3 python3-pip nodejs npm
else
  echo "[CrewUp] apt-get not found; skipping OS package install"
fi

if command -v npm >/dev/null 2>&1; then
  echo "[CrewUp] installing npm dependencies"
  npm install

  echo "[CrewUp] installing optional global CLIs: netlify-cli, supabase"
  sudo npm install -g netlify-cli supabase || npm install -g netlify-cli supabase || true
else
  echo "[CrewUp] npm not found; install Node.js/npm manually"
fi

mkdir -p \
  "$PROJECT_DIR/Obsidian_Vault/00_Inbox" \
  "$PROJECT_DIR/Obsidian_Vault/10_CrewUp" \
  "$PROJECT_DIR/Obsidian_Vault/20_AI_Agent" \
  "$PROJECT_DIR/Obsidian_Vault/30_Web_Design" \
  "$PROJECT_DIR/Obsidian_Vault/40_YouTube" \
  "$PROJECT_DIR/Obsidian_Vault/50_Daily" \
  "$PROJECT_DIR/Obsidian_Vault/90_Agent_Reports" \
  "$PROJECT_DIR/Obsidian_Vault/98_Attachments" \
  "$PROJECT_DIR/Obsidian_Vault/99_Templates"

if [ ! -f "$PROJECT_DIR/.env" ]; then
  cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
  echo "[CrewUp] created .env from .env.example. Fill real values manually."
else
  echo "[CrewUp] .env already exists; leaving it untouched."
fi

HERMES_ENV="$HOME/.hermes/.env"
mkdir -p "$(dirname "$HERMES_ENV")"
if ! grep -q '^OBSIDIAN_VAULT_PATH=' "$HERMES_ENV" 2>/dev/null; then
  printf '\nOBSIDIAN_VAULT_PATH=%s/Obsidian_Vault\n' "$PROJECT_DIR" >> "$HERMES_ENV"
  echo "[CrewUp] added OBSIDIAN_VAULT_PATH to $HERMES_ENV"
else
  echo "[CrewUp] OBSIDIAN_VAULT_PATH already exists in $HERMES_ENV"
fi

if [ ! -f "$PROJECT_DIR/crewup_official_site/config.js" ] && [ -f "$PROJECT_DIR/crewup_official_site/config.example.js" ]; then
  cp "$PROJECT_DIR/crewup_official_site/config.example.js" "$PROJECT_DIR/crewup_official_site/config.js"
  echo "[CrewUp] created crewup_official_site/config.js from example. Fill Supabase anon config manually."
else
  echo "[CrewUp] crewup_official_site/config.js already exists or example missing; leaving it untouched."
fi

echo "[CrewUp] versions"
git --version || true
node --version || true
npm --version || true
python3 --version || true
netlify --version || true
supabase --version || true

echo "[CrewUp] bootstrap complete"
echo "Next: edit .env and crewup_official_site/config.js, then run:"
echo "  cd crewup_official_site && python3 -m http.server 4177"
