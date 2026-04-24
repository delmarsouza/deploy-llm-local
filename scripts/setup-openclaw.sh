#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROFILE="${1:-${PROFILE:-}}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
GATEWAY_URL="${OPENCLAW_GATEWAY_URL:-ws://127.0.0.1:18789}"
OLLAMA_URL="${OLLAMA_BASE_URL:-http://127.0.0.1:11434}"
OPENWEBUI_URL="${OPENWEBUI_URL:-http://127.0.0.1:3000}"

log() { echo -e "${BLUE}[deploy-llm-local]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err() { echo -e "${RED}[erro]${NC} $*"; }

require_openclaw() {
  if ! command -v openclaw >/dev/null 2>&1; then
    err "OpenClaw não encontrado. Instala/configura o OpenClaw antes de seguir."
    exit 1
  fi
}

normalize_profile() {
  case "${PROFILE,,}" in
    6gb|6)
      PROFILE="6GB"
      ;;
    8gb|8)
      PROFILE="8GB"
      ;;
    16gb|16)
      PROFILE="16GB"
      ;;
    "")
      PROFILE="AUTO"
      ;;
    *)
      err "Perfil inválido: ${PROFILE}. Usa 6gb, 8gb ou 16gb."
      exit 1
      ;;
  esac
}

ensure_workspace() {
  log "Preparando workspace do OpenClaw em ${WORKSPACE_DIR}..."
  mkdir -p "${WORKSPACE_DIR}"
  openclaw setup --mode local --non-interactive --workspace "${WORKSPACE_DIR}" >/dev/null 2>&1 || \
    warn "openclaw setup retornou aviso; vou seguir validando a instalação atual."
  ok "Workspace preparado."
}

ensure_gateway_service() {
  log "Garantindo gateway do OpenClaw..."
  if openclaw gateway health >/dev/null 2>&1; then
    ok "Gateway já estava saudável."
    return 0
  fi

  warn "Gateway não respondeu; tentando iniciar o serviço..."
  openclaw gateway start >/dev/null 2>&1 || openclaw gateway install --force >/dev/null 2>&1 || true
  openclaw gateway start >/dev/null 2>&1 || true

  for _ in $(seq 1 10); do
    if openclaw gateway health >/dev/null 2>&1; then
      ok "Gateway iniciado com sucesso."
      return 0
    fi
    sleep 2
  done

  warn "Gateway ainda não respondeu; pode precisar de ajuste manual."
}

write_env_example() {
  mkdir -p "${REPO_DIR}/examples"
  local target="${REPO_DIR}/examples/openclaw.env.example"
  cat > "$target" <<ENVEOF
# Perfil escolhido para o projeto
PROFILE=${PROFILE}

# Workspace e gateway OpenClaw
OPENCLAW_WORKSPACE_DIR=${WORKSPACE_DIR}
OPENCLAW_GATEWAY_URL=${GATEWAY_URL}
OPENCLAW_GATEWAY_TOKEN=

# Backend local
OLLAMA_BASE_URL=${OLLAMA_URL}
OPENWEBUI_URL=${OPENWEBUI_URL}

# Canais opcionais
TELEGRAM_BOT_TOKEN=
TELEGRAM_ALLOW_FROM=
SLACK_BOT_TOKEN=
SLACK_APP_TOKEN=
SLACK_CHANNEL=
ENVEOF
  ok "Arquivo de exemplo gerado: examples/openclaw.env.example"
}

check_gateway() {
  log "Verificando gateway do OpenClaw..."
  openclaw gateway status || true
  if openclaw gateway health >/dev/null 2>&1; then
    ok "Gateway respondeu ao health check final."
  else
    warn "Gateway segue instável no health check final."
  fi
}

check_channels() {
  log "Consultando canais configurados..."
  openclaw status || true
}

check_ollama() {
  log "Validando backend local de modelo..."
  if curl -fsS "${OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
    ok "Ollama respondeu em ${OLLAMA_URL}"
  else
    warn "Ollama não respondeu em ${OLLAMA_URL}"
  fi
}

check_openwebui() {
  log "Validando Open WebUI..."
  if curl -fsS "${OPENWEBUI_URL}" >/dev/null 2>&1; then
    ok "Open WebUI respondeu em ${OPENWEBUI_URL}"
  else
    warn "Open WebUI não respondeu em ${OPENWEBUI_URL}"
  fi
}

show_summary() {
  echo
  ok "Setup do OpenClaw concluído."
  echo "- Perfil: ${PROFILE}"
  echo "- Workspace: ${WORKSPACE_DIR}"
  echo "- Gateway esperado: ${GATEWAY_URL}"
  echo "- Arquivo exemplo: examples/openclaw.env.example"
  echo "- Canais automatizáveis: Telegram e Slack"
}

main() {
  normalize_profile
  require_openclaw
  ensure_workspace
  ensure_gateway_service
  write_env_example
  check_gateway
  check_channels
  check_ollama
  check_openwebui
  show_summary
}

main "$@"
