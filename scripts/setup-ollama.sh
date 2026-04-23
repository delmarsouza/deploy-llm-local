#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

log() { echo -e "${BLUE}[deploy-llm-local]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err() { echo -e "${RED}[erro]${NC} $*"; }

require_sudo() {
  if ! sudo -n true >/dev/null 2>&1; then
    err "sudo sem senha é necessário para este script."
    err "Configura sudo NOPASSWD ou executa manualmente os comandos com sudo."
    exit 1
  fi
}

require_linux() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    err "Este script foi feito para Linux."
    exit 1
  fi
}

install_ollama() {
  if command -v ollama >/dev/null 2>&1; then
    ok "Ollama já está instalado: $(ollama --version 2>/dev/null || echo 'versão não identificada')"
    return
  fi

  log "Instalando Ollama..."
  curl -fsSL https://ollama.com/install.sh | sh
  ok "Ollama instalado."
}

enable_service() {
  if systemctl list-unit-files | grep -q '^ollama.service'; then
    log "Habilitando e iniciando serviço do Ollama..."
    sudo -n systemctl enable --now ollama
    ok "Serviço ollama habilitado e iniciado."
  else
    warn "Serviço ollama.service não encontrado. Vou seguir com validação por binário."
  fi
}

wait_for_ollama() {
  local max_attempts=20
  local attempt=1

  while (( attempt <= max_attempts )); do
    if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      ok "API do Ollama respondeu em http://127.0.0.1:11434"
      return 0
    fi
    sleep 1
    ((attempt++))
  done

  return 1
}

validate_install() {
  log "Validando instalação do Ollama..."
  ollama --version

  if systemctl list-unit-files | grep -q '^ollama.service'; then
    sudo -n systemctl --no-pager --full status ollama | sed -n '1,20p' || true
  fi

  if wait_for_ollama; then
    curl -fsS http://127.0.0.1:11434/api/tags
    ok "Ollama está operacional."
  else
    err "O serviço/API do Ollama não respondeu dentro do tempo esperado."
    err "Confere com: sudo systemctl status ollama"
    exit 1
  fi
}

main() {
  log "Iniciando setup do Ollama..."
  require_linux
  require_sudo
  install_ollama
  enable_service
  validate_install
  ok "Etapa setup-ollama concluída."
}

main "$@"
