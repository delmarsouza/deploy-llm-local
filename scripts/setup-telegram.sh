#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${1:-${REPO_DIR}/examples/telegram.env.example}"
TMP_ALLOWLIST="/tmp/openclaw-telegram-allowlist.json"

log() { echo -e "${BLUE}[deploy-llm-local]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err() { echo -e "${RED}[erro]${NC} $*"; }

require_openclaw() {
  if ! command -v openclaw >/dev/null 2>&1; then
    err "OpenClaw não encontrado."
    exit 1
  fi
}

load_env() {
  if [[ ! -f "$ENV_FILE" ]]; then
    err "Arquivo de ambiente não encontrado: $ENV_FILE"
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}

validate_env() {
  if [[ -z "${TELEGRAM_BOT_TOKEN:-}" ]]; then
    err "TELEGRAM_BOT_TOKEN não informado em $ENV_FILE"
    exit 1
  fi
}

apply_channel() {
  log "Configurando conta Telegram no OpenClaw..."
  openclaw channels add --channel telegram --token "$TELEGRAM_BOT_TOKEN" --account default
  ok "Conta Telegram registrada."
}

apply_policies() {
  log "Aplicando políticas do canal Telegram..."
  openclaw config set channels.telegram.enabled true --strict-json
  openclaw config set channels.telegram.dmPolicy '"allowlist"' --strict-json
  openclaw config set channels.telegram.groupPolicy '"allowlist"' --strict-json
  openclaw config set channels.telegram.streaming.mode '"partial"' --strict-json

  if [[ -n "${TELEGRAM_ALLOW_FROM:-}" ]]; then
    python3 - <<PY > "$TMP_ALLOWLIST"
import json
values=[v.strip() for v in """${TELEGRAM_ALLOW_FROM}""".split(',') if v.strip()]
print(json.dumps(values))
PY
    openclaw config set channels.telegram.allowFrom --batch-file "$TMP_ALLOWLIST" >/dev/null 2>&1 || \
      openclaw config set channels.telegram.allowFrom "$(cat "$TMP_ALLOWLIST")" --strict-json
    ok "Allowlist aplicada: ${TELEGRAM_ALLOW_FROM}"
  else
    warn "TELEGRAM_ALLOW_FROM vazio; canal fica em allowlist sem entradas."
  fi
}

restart_gateway() {
  log "Reiniciando gateway do OpenClaw..."
  openclaw gateway restart || openclaw gateway start

  local ready=''
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if openclaw gateway health >/dev/null 2>&1; then
      ready=1
      break
    fi
    sleep 2
  done

  if [[ -z "$ready" ]]; then
    err "Gateway não ficou saudável após reinício."
    openclaw gateway status || true
    exit 1
  fi
}

validate_channel() {
  log "Validando canal Telegram..."
  openclaw channels list
  openclaw channels status --probe || true
  openclaw status --deep || true
}

show_summary() {
  echo
  ok "Setup do Telegram concluído."
  echo "- Env file usado: ${ENV_FILE}"
  echo "- Token configurado: sim"
  echo "- Allowlist configurada: ${TELEGRAM_ALLOW_FROM:-<vazia>}"
}

main() {
  require_openclaw
  load_env
  validate_env
  apply_channel
  apply_policies
  restart_gateway
  validate_channel
  show_summary
}

main "$@"
