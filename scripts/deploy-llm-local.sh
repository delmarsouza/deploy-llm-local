#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROFILE=""
CHANNEL="none"
SKIP_DOCKER=0
SKIP_NVIDIA=0
SKIP_OLLAMA=0
SKIP_OPENWEBUI=0
SKIP_OPENCLAW=0
CHANNEL_ENV_FILE=""

log() { echo -e "${BLUE}[deploy-llm-local]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err() { echo -e "${RED}[erro]${NC} $*"; }

usage() {
  cat <<USAGE
Uso:
  scripts/deploy-llm-local.sh [opções]

Opções:
  --profile <6gb|8gb|16gb>        Força o perfil de hardware
  --channel <telegram|slack|none> Define se tenta configurar canal
  --channel-env <arquivo>         Arquivo .env do canal escolhido
  --skip-docker                   Pula instalação do Docker
  --skip-nvidia                   Pula NVIDIA Container Toolkit
  --skip-ollama                   Pula setup do Ollama
  --skip-openwebui                Pula setup do Open WebUI
  --skip-openclaw                 Pula setup do OpenClaw
  -h, --help                      Mostra esta ajuda

Exemplos:
  scripts/deploy-llm-local.sh
  scripts/deploy-llm-local.sh --profile 16gb --channel telegram --channel-env examples/telegram.env.example
  scripts/deploy-llm-local.sh --skip-docker --skip-nvidia
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --profile)
        PROFILE="${2:-}"
        shift 2
        ;;
      --channel)
        CHANNEL="${2:-}"
        shift 2
        ;;
      --channel-env)
        CHANNEL_ENV_FILE="${2:-}"
        shift 2
        ;;
      --skip-docker)
        SKIP_DOCKER=1
        shift
        ;;
      --skip-nvidia)
        SKIP_NVIDIA=1
        shift
        ;;
      --skip-ollama)
        SKIP_OLLAMA=1
        shift
        ;;
      --skip-openwebui)
        SKIP_OPENWEBUI=1
        shift
        ;;
      --skip-openclaw)
        SKIP_OPENCLAW=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Opção inválida: $1"
        usage
        exit 1
        ;;
    esac
  done
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
      ;;
    *)
      err "Perfil inválido: ${PROFILE}. Usa 6gb, 8gb ou 16gb."
      exit 1
      ;;
  esac
}

detect_profile() {
  local gpu_vram_mib=0
  local mem_total_gib=0

  if command -v nvidia-smi >/dev/null 2>&1; then
    gpu_vram_mib="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1 | xargs)"
  fi
  mem_total_gib="$(awk '/MemTotal/ { printf "%.0f", $2/1024/1024 }' /proc/meminfo)"

  if [[ -z "$PROFILE" ]]; then
    if [[ "$gpu_vram_mib" -ge 14336 && "$mem_total_gib" -ge 32 ]]; then
      PROFILE="16GB"
    elif [[ "$gpu_vram_mib" -ge 7168 && "$mem_total_gib" -ge 16 ]]; then
      PROFILE="8GB"
    elif [[ "$gpu_vram_mib" -ge 5120 && "$mem_total_gib" -ge 8 ]]; then
      PROFILE="6GB"
    else
      err "Não consegui detectar um perfil suportado automaticamente. Usa --profile 6gb|8gb|16gb."
      exit 1
    fi
  fi

  ok "Perfil selecionado: ${PROFILE}"
}

validate_channel() {
  case "$CHANNEL" in
    telegram|slack|none)
      ;;
    *)
      err "Canal inválido: ${CHANNEL}. Usa telegram, slack ou none."
      exit 1
      ;;
  esac
}

run_step() {
  local label="$1"
  shift
  log "Executando etapa: ${label}"
  bash "$@"
  ok "Etapa concluída: ${label}"
}

maybe_setup_channel() {
  case "$CHANNEL" in
    telegram)
      if [[ -n "$CHANNEL_ENV_FILE" ]]; then
        run_step "setup-telegram" "${REPO_DIR}/scripts/setup-telegram.sh" "$CHANNEL_ENV_FILE"
      else
        warn "Canal telegram pedido, mas --channel-env não foi informado. Pulando automação do canal."
      fi
      ;;
    slack)
      if [[ -n "$CHANNEL_ENV_FILE" ]]; then
        run_step "setup-slack" "${REPO_DIR}/scripts/setup-slack.sh" "$CHANNEL_ENV_FILE"
      else
        warn "Canal slack pedido, mas --channel-env não foi informado. Pulando automação do canal."
      fi
      ;;
    none)
      ;;
  esac
}

show_summary() {
  local env_file="docker/env/${PROFILE,,}.env"
  local compose_file="docker/compose.${PROFILE,,}.yml"

  echo
  ok "Bootstrap principal concluído."
  echo "- Perfil: ${PROFILE}"
  echo "- Canal: ${CHANNEL}"
  echo "- Env do perfil: ${env_file}"
  echo "- Compose do perfil: ${compose_file}"

  if [[ -n "$CHANNEL_ENV_FILE" ]]; then
    echo "- Env do canal: ${CHANNEL_ENV_FILE}"
  fi

  echo
  echo "Próximos comandos úteis:"
  echo "- bash scripts/setup-openwebui.sh ${PROFILE,,}"
  echo "- bash scripts/setup-openclaw.sh ${PROFILE,,}"
  echo "- openclaw status"
}

main() {
  parse_args "$@"
  normalize_profile
  validate_channel

  log "Iniciando bootstrap do Deploy LLM Local..."
  run_step "check-system" "${REPO_DIR}/scripts/check-system.sh"
  detect_profile

  if [[ "$SKIP_DOCKER" -eq 0 ]]; then
    run_step "install-docker" "${REPO_DIR}/scripts/install-docker.sh"
  else
    warn "Pulando install-docker por opção do usuário."
  fi

  if [[ "$SKIP_NVIDIA" -eq 0 ]]; then
    run_step "install-nvidia-toolkit" "${REPO_DIR}/scripts/install-nvidia-toolkit.sh"
  else
    warn "Pulando install-nvidia-toolkit por opção do usuário."
  fi

  if [[ "$SKIP_OLLAMA" -eq 0 ]]; then
    run_step "setup-ollama" "${REPO_DIR}/scripts/setup-ollama.sh"
  else
    warn "Pulando setup-ollama por opção do usuário."
  fi

  if [[ "$SKIP_OPENWEBUI" -eq 0 ]]; then
    run_step "setup-openwebui" "${REPO_DIR}/scripts/setup-openwebui.sh" "${PROFILE,,}"
  else
    warn "Pulando setup-openwebui por opção do usuário."
  fi

  if [[ "$SKIP_OPENCLAW" -eq 0 ]]; then
    run_step "setup-openclaw" "${REPO_DIR}/scripts/setup-openclaw.sh" "${PROFILE,,}"
  else
    warn "Pulando setup-openclaw por opção do usuário."
  fi

  maybe_setup_channel
  show_summary
}

main "$@"
