#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${1:-${REPO_DIR}/examples/slack.env.example}"

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
  if [[ -z "${SLACK_BOT_TOKEN:-}" ]]; then
    err "SLACK_BOT_TOKEN não informado em $ENV_FILE"
    exit 1
  fi

  if [[ -z "${SLACK_APP_TOKEN:-}" ]]; then
    err "SLACK_APP_TOKEN não informado em $ENV_FILE"
    exit 1
  fi

  if [[ -z "${SLACK_CHANNEL:-}" ]]; then
    warn "SLACK_CHANNEL não informado. O canal ficará sem destino padrão explícito."
  fi
}

apply_config() {
  log "Aplicando configuração do Slack no OpenClaw..."
  openclaw config set channels.slack.enabled true --strict-json
  openclaw config set channels.slack.botToken "\"${SLACK_BOT_TOKEN}\"" --strict-json
  openclaw config set channels.slack.appToken "\"${SLACK_APP_TOKEN}\"" --strict-json
  openclaw config set channels.slack.streaming '"partial"' --strict-json

  if [[ -n "${SLACK_CHANNEL:-}" ]]; then
    openclaw config set channels.slack.defaultChannel "\"${SLACK_CHANNEL}\"" --strict-json || \
    warn "Não consegui gravar defaultChannel automaticamente; segue sem canal padrão."
  fi

  ok "Configuração do Slack aplicada."
}

restart_gateway_if_possible() {
  log "Recarregando gateway do OpenClaw..."
  openclaw gateway restart || warn "Não consegui reiniciar o gateway automaticamente."
}

validate_channel() {
  log "Validando canal Slack..."
  openclaw channels status --probe || true
  openclaw status || true
}

show_summary() {
  echo
  ok "Setup do Slack concluído."
  echo "- Env file usado: ${ENV_FILE}"
  echo "- Bot token configurado: sim"
  echo "- App token configurado: sim"
  echo "- Canal padrão: ${SLACK_CHANNEL:-<não definido>}"
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
