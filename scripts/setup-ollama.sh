#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[setup-ollama] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "comando obrigatório ausente: $1"
    exit 1
  }
}

SUDO=''
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  SUDO='sudo -n'
fi

require_cmd curl
require_cmd systemctl

install_ollama() {
  if command -v ollama >/dev/null 2>&1; then
    log "ollama já instalado: $(ollama --version 2>/dev/null || true)"
    return 0
  fi

  log "instalando Ollama"
  curl -fsSL https://ollama.com/install.sh | sh
}

ensure_service() {
  if systemctl list-unit-files | grep -q '^ollama.service'; then
    log "habilitando e iniciando ollama.service"
    $SUDO systemctl enable --now ollama.service
  elif systemctl --user list-unit-files | grep -q '^ollama.service'; then
    log "habilitando e iniciando ollama.service no user systemd"
    systemctl --user enable --now ollama.service
  else
    log "serviço systemd do Ollama não encontrado; tentando subir em background"
    if ! pgrep -x ollama >/dev/null 2>&1; then
      nohup ollama serve >/tmp/ollama-serve.log 2>&1 &
      sleep 3
    fi
  fi
}

validate_install() {
  require_cmd ollama
  log "versão: $(ollama --version)"

  local ok=''
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      ok=1
      break
    fi
    sleep 2
  done

  if [ -z "$ok" ]; then
    log "API do Ollama não respondeu em http://127.0.0.1:11434"
    exit 1
  fi

  log "API do Ollama respondendo em 127.0.0.1:11434"
}

install_ollama
ensure_service
validate_install
log "concluído com sucesso"
