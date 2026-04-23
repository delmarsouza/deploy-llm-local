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

  if [[ -z "${TELEGRAM_ALLOW_FROM:-}" ]]; then
    warn "TELEGRAM_ALLOW_FROM não informado. Vou manter allowlist vazia se aplicar configuração nova."
  fi
}

apply_config() {
  log "Aplicando configuração do Telegram no OpenClaw..."
  openclaw config set channels.telegram.enabled true --strict-json
  openclaw config set channels.telegram.botToken "\"${TELEGRAM_BOT_TOKEN}\"" --strict-json
  openclaw config set channels.telegram.dmPolicy '"allowlist"' --strict-json
  openclaw config set channels.telegram.groupPolicy '"allowlist"' --strict-json
  openclaw config set channels.telegram.streaming '"partial"' --strict-json

  if [[ -n "${TELEGRAM_ALLOW_FROM:-}" ]]; then
    python3 - <<PY >/tmp/openclaw-telegram-allowlist.json
import json
values=[v.strip() for v in """${TELEGRAM_ALLOW_FROM}""".split(',') if v.strip()]
print(json.dumps(values))
PY
    openclaw config set channels.telegram.allowFrom --batch-file /tmp/openclaw-telegram-allowlist.json >/dev/null 2>&1 && true || \
    openclaw config set channels.telegram.allowFrom "$(cat /tmp/openclaw-telegram-allowlist.json)" --strict-json
  fi

  ok "Configuração do Telegram aplicada."
}

restart_gateway_if_possible() {
  log "Recarregando gateway do OpenClaw..."
  openclaw gateway restart || warn "Não consegui reiniciar o gateway automaticamente."
}

validate_channel() {
  log "Validando canal Telegram..."
  openclaw channels status --probe || true
  openclaw status || true
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
  apply_config
  restart_gateway_if_possible
  validate_channel
  show_summary
}

main "$@"
