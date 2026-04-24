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

require_openclaw() {
  if ! command -v openclaw >/dev/null 2>&1; then
    err "OpenClaw não encontrado."
    exit 1
  fi
}

apply_safe_defaults() {
  log "Aplicando defaults seguros não destrutivos..."
  openclaw config set gateway.bind '"loopback"' --strict-json || true
  ok "gateway.bind ajustado para loopback (quando aplicável)."
}

report_security() {
  log "Rodando auditoria de segurança do OpenClaw..."
  openclaw security audit || true
}

show_summary() {
  echo
  ok "Passo de hardening concluído."
  echo "- Gateway preferencialmente local-only"
  echo "- Próximo passo manual recomendado: revisar docs/hardening.md"
  echo "- Auditoria: openclaw security audit --deep"
}

main() {
  require_openclaw
  apply_safe_defaults
  report_security
  show_summary
}

main "$@"
