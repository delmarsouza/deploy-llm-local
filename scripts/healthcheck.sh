#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

ok() { echo -e "${GREEN}[PASS]${NC} $*"; PASS_COUNT=$((PASS_COUNT+1)); }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; WARN_COUNT=$((WARN_COUNT+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAIL_COUNT=$((FAIL_COUNT+1)); }
section() { echo -e "${BLUE}\n== $* ==${NC}"; }

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    ok "Comando disponível: $name"
  else
    fail "Comando ausente: $name"
  fi
}

check_http_required() {
  local url="$1"
  local label="$2"
  if curl -fsS "$url" >/dev/null 2>&1; then
    ok "$label respondeu em $url"
  else
    fail "$label não respondeu em $url"
  fi
}

check_http_optional() {
  local url="$1"
  local label="$2"
  if curl -fsS "$url" >/dev/null 2>&1; then
    ok "$label respondeu em $url"
  else
    warn "$label não respondeu em $url"
  fi
}

section "Base"
check_cmd docker
check_cmd ollama
check_cmd openclaw
check_cmd curl

section "Docker"
if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    ok "Docker daemon acessível"
  else
    fail "Docker instalado, mas daemon inacessível"
  fi

  if docker compose version >/dev/null 2>&1; then
    ok "Docker Compose disponível"
  else
    fail "Docker Compose indisponível"
  fi
fi

section "GPU"
if command -v nvidia-smi >/dev/null 2>&1; then
  ok "nvidia-smi disponível"
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || true
else
  warn "nvidia-smi não disponível neste host"
fi

section "Ollama"
if command -v ollama >/dev/null 2>&1; then
  ollama --version || true
  check_http_required "http://127.0.0.1:11434/api/tags" "Ollama API"
fi

section "Open WebUI"
check_http_optional "http://127.0.0.1:3001" "Open WebUI"

section "OpenClaw"
if command -v openclaw >/dev/null 2>&1; then
  if openclaw gateway health >/dev/null 2>&1; then
    ok "Gateway OpenClaw saudável"
  else
    fail "Gateway OpenClaw não respondeu ao health check"
  fi

  if openclaw gateway probe 2>/dev/null | grep -q 'Reachable: yes'; then
    ok "Gateway OpenClaw acessível via probe"
  else
    fail "Gateway OpenClaw sem resposta válida no probe"
  fi

  if openclaw status >/dev/null 2>&1; then
    ok "OpenClaw status executou com sucesso"
  else
    fail "OpenClaw status falhou"
  fi

  if openclaw channels status --probe 2>/dev/null | grep -q 'Telegram default: .*works'; then
    ok "Telegram ativo e funcional"
  else
    warn "Telegram não apareceu como funcional no probe"
  fi
fi

section "Resumo"
echo "PASS=${PASS_COUNT} WARN=${WARN_COUNT} FAIL=${FAIL_COUNT}"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
