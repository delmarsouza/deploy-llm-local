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
GATEWAY_LOG="/tmp/openclaw/openclaw-$(date +%F).log"

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

apply_channel() {
  log "Configurando conta Slack no OpenClaw..."
  openclaw channels add --channel slack --bot-token "$SLACK_BOT_TOKEN" --app-token "$SLACK_APP_TOKEN" --account default
  ok "Conta Slack registrada."
}

apply_policies() {
  log "Aplicando políticas do Slack..."
  openclaw config set channels.slack.enabled true --strict-json
  openclaw config set channels.slack.mode '"socket"' --strict-json
  openclaw config set channels.slack.streaming.mode '"partial"' --strict-json

  if [[ -n "${SLACK_CHANNEL:-}" ]]; then
    openclaw config set channels.slack.defaultTo "\"${SLACK_CHANNEL}\"" --strict-json || \
      warn "Não consegui gravar defaultTo automaticamente; segue sem canal padrão."
  fi

  ok "Configuração do Slack aplicada."
}

restart_gateway() {
  log "Reiniciando gateway do OpenClaw..."
  openclaw gateway restart || openclaw gateway start
}

diagnose_slack_failure() {
  local combined
  combined="$( (openclaw channels logs 2>/dev/null | tail -n 200; journalctl --user -u openclaw-gateway.service -n 120 --no-pager 2>/dev/null | tail -n 120) || true )"

  if echo "$combined" | grep -q 'invalid_auth'; then
    err "SLACK_AUTH_INVALID: credenciais do Slack rejeitadas pela API."
    return 11
  fi

  if echo "$combined" | grep -q "Cannot find module '@slack/web-api'"; then
    err "SLACK_RUNTIME_DEP_MISSING: runtime do Slack sem @slack/web-api disponível."
    return 12
  fi

  if echo "$combined" | grep -q 'gateway closed (1006 abnormal closure'; then
    err "GATEWAY_NOT_READY_OR_CRASHED: gateway fechou durante a inicialização do Slack."
    return 13
  fi

  err "SLACK_SETUP_FAILED: falha não classificada automaticamente."
  return 14
}

wait_for_gateway_or_diagnose() {
  log "Aguardando gateway e canal Slack estabilizarem..."

  for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if openclaw gateway health >/dev/null 2>&1; then
      status_out="$(openclaw channels status --probe 2>&1 || true)"
      if echo "$status_out" | grep -q 'Slack'; then
        if echo "$status_out" | grep -Eq 'works|running|connected|enabled'; then
          ok "Slack respondeu ao probe do OpenClaw."
          return 0
        fi
        if echo "$status_out" | grep -q 'invalid_auth'; then
          err "SLACK_AUTH_INVALID: credenciais do Slack rejeitadas pela API."
          return 11
        fi
      fi
    fi
    sleep 3
  done

  diagnose_slack_failure
}

validate_channel() {
  log "Validando canal Slack..."
  openclaw channels list || true
  openclaw channels status --probe || true
  openclaw status --deep || true
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
  apply_channel
  apply_policies
  restart_gateway
  wait_for_gateway_or_diagnose
  validate_channel
  show_summary
}

main "$@"
