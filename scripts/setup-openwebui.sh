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

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    err "Docker não encontrado neste contexto de execução. Roda scripts/install-docker.sh no host alvo antes."
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    err "Docker está instalado, mas não está acessível para o usuário atual."
    err "Confere permissões do grupo docker ou executa com um usuário que tenha acesso ao daemon."
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
      err "Perfil não informado. Usa: scripts/setup-openwebui.sh 6gb|8gb|16gb"
      exit 1
      ;;
    *)
      err "Perfil inválido: ${PROFILE}. Usa 6gb, 8gb ou 16gb."
      exit 1
      ;;
  esac
}

resolve_files() {
  ENV_FILE="${REPO_DIR}/docker/env/${PROFILE,,}.env"
  COMPOSE_BASE="${REPO_DIR}/docker/compose.base.yml"
  COMPOSE_PROFILE="${REPO_DIR}/docker/compose.${PROFILE,,}.yml"

  [[ -f "$ENV_FILE" ]] || { err "Env file não encontrado: $ENV_FILE"; exit 1; }
  [[ -f "$COMPOSE_BASE" ]] || { err "Compose base não encontrado: $COMPOSE_BASE"; exit 1; }
  [[ -f "$COMPOSE_PROFILE" ]] || { err "Compose do perfil não encontrado: $COMPOSE_PROFILE"; exit 1; }
}

check_ollama() {
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    ok "Ollama local respondeu em 127.0.0.1:11434"
  else
    warn "Ollama não respondeu em 127.0.0.1:11434. O Open WebUI pode subir sem backend funcional até isso ser resolvido."
  fi
}

compose_up() {
  log "Subindo Open WebUI para o perfil ${PROFILE}..."
  docker compose \
    --env-file "$ENV_FILE" \
    -f "$COMPOSE_BASE" \
    -f "$COMPOSE_PROFILE" \
    up -d
}

show_compose_status() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_BASE" -f "$COMPOSE_PROFILE" ps || true
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_BASE" -f "$COMPOSE_PROFILE" logs --tail=50 || true
}

validate_ui() {
  local port
  port="$(grep '^OPENWEBUI_PORT=' "$ENV_FILE" | cut -d= -f2)"
  port="${port:-3000}"

  log "Validando Open WebUI em http://127.0.0.1:${port} ..."
  for _ in $(seq 1 30); do
    if curl -fsS "http://127.0.0.1:${port}" >/dev/null 2>&1; then
      ok "Open WebUI respondeu em http://127.0.0.1:${port}"
      return 0
    fi
    sleep 2
  done

  err "Open WebUI não respondeu dentro do tempo esperado."
  show_compose_status
  exit 1
}

show_summary() {
  local port
  port="$(grep '^OPENWEBUI_PORT=' "$ENV_FILE" | cut -d= -f2)"
  port="${port:-3000}"

  echo
  ok "Open WebUI configurado com sucesso."
  echo "- Perfil: ${PROFILE}"
  echo "- URL local: http://127.0.0.1:${port}"
  echo "- Env file: ${ENV_FILE}"
  echo "- Compose base: ${COMPOSE_BASE}"
  echo "- Compose perfil: ${COMPOSE_PROFILE}"
}

main() {
  normalize_profile
  require_docker
  resolve_files
  check_ollama
  compose_up
  validate_ui
  show_summary
}

main "$@"
