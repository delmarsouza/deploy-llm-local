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
  mkdir -p "${REPO_DIR}/examples"
}

write_env_example() {
  local target="${REPO_DIR}/examples/openclaw.env.example"
  cat > "$target" <<ENVEOF
# Perfil escolhido para o projeto
PROFILE=${PROFILE}

# Gateway OpenClaw
OPENCLAW_GATEWAY_URL=ws://127.0.0.1:18789
OPENCLAW_GATEWAY_TOKEN=

# Modelo/backend local
OLLAMA_BASE_URL=http://127.0.0.1:11434
OPENWEBUI_URL=http://127.0.0.1:3000

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
  if openclaw gateway health >/dev/null 2>&1; then
    ok "Gateway do OpenClaw está saudável."
  else
    warn "Gateway não respondeu no primeiro teste. Vou consultar status geral."
  fi

  openclaw gateway status || true
}

check_channels() {
  log "Consultando canais configurados..."
  openclaw status || true
}

check_ollama() {
  log "Validando backend local de modelo..."
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    ok "Ollama respondeu em 127.0.0.1:11434"
  else
    warn "Ollama não respondeu em 127.0.0.1:11434"
  fi
}

show_summary() {
  echo
  ok "Setup base de OpenClaw concluído."
  echo "- Perfil: ${PROFILE}"
  echo "- Gateway esperado: ws://127.0.0.1:18789"
  echo "- Arquivo exemplo: examples/openclaw.env.example"
  echo "- Próximo passo: implementar scripts/setup-telegram.sh e scripts/setup-slack.sh para automação completa dos canais"
}

main() {
  normalize_profile
  require_openclaw
  ensure_workspace
  write_env_example
  check_gateway
  check_channels
  check_ollama
  show_summary
}

main "$@"
