#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="$CONFIG_DIR/workspace"
LOG_DIR="$CONFIG_DIR/logs"
TOTAL_STEPS=5
CURRENT_STEP=0

log() {
  printf '[setup-openclaw] %s\n' "$*"
}

step_log() {
  printf '[setup-openclaw] [%s/%s] %s\n' "$1" "$TOTAL_STEPS" "$2"
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
require_cmd python3

install_node_if_missing() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    log "node já presente: $(node -v) / npm $(npm -v)"
    return 0
  fi

  log "instalando Node.js e npm"
  $SUDO apt-get update
  $SUDO apt-get install -y nodejs npm
}

install_openclaw_if_missing() {
  if command -v openclaw >/dev/null 2>&1; then
    log "openclaw já presente: $(openclaw --version 2>/dev/null || true)"
    return 0
  fi

  log "instalando OpenClaw globalmente via npm"
  $SUDO npm install -g openclaw@latest
}

write_project_safe_config() {
  mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR" "$LOG_DIR"
  python3 - <<PY
import json, os, secrets
p=os.path.expanduser('$CONFIG_FILE')
workspace=os.path.expanduser('$WORKSPACE_DIR')
if os.path.exists(p):
    with open(p) as f:
        cfg=json.load(f)
else:
    cfg={}

cfg.setdefault('gateway', {})
cfg['gateway']['mode'] = 'local'
cfg['gateway'].setdefault('auth', {})
cfg['gateway']['auth'].setdefault('mode', 'token')
cfg['gateway']['auth'].setdefault('token', secrets.token_hex(24))
cfg['gateway'].setdefault('bind', 'loopback')
cfg['gateway'].setdefault('port', 18789)

cfg.setdefault('agents', {}).setdefault('defaults', {})
cfg['agents']['defaults'].setdefault('workspace', workspace)

cfg.setdefault('plugins', {}).setdefault('entries', {})
cfg['plugins']['entries'].setdefault('ollama', {'enabled': True, 'config': {'discovery': {'enabled': True}}})

cfg.setdefault('models', {}).setdefault('mode', 'merge')
providers=cfg['models'].setdefault('providers', {})
ollama=providers.setdefault('ollama', {})
ollama.setdefault('baseUrl', 'http://127.0.0.1:11434')
ollama.setdefault('api', 'ollama')
ollama.setdefault('apiKey', 'OLLAMA_API_KEY')
ollama.setdefault('models', [])

with open(p,'w') as f:
    json.dump(cfg, f, indent=2)

summary = {
    'config_file': p,
    'gateway_mode': cfg.get('gateway', {}).get('mode'),
    'gateway_bind': cfg.get('gateway', {}).get('bind'),
    'gateway_port': cfg.get('gateway', {}).get('port'),
    'workspace': cfg.get('agents', {}).get('defaults', {}).get('workspace'),
    'ollama_base_url': cfg.get('models', {}).get('providers', {}).get('ollama', {}).get('baseUrl'),
}
print(json.dumps(summary, indent=2))
PY
}

ensure_gateway_ready() {
  log "instalando/habilitando serviço do gateway"
  openclaw gateway install
  systemctl --user daemon-reload || true
  openclaw gateway restart || openclaw gateway start

  log "aguardando gateway ficar acessível; esta etapa pode levar alguns segundos enquanto o serviço aquece"
  ready=''
  for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    if openclaw gateway health >/dev/null 2>&1; then
      if openclaw gateway probe 2>/dev/null | grep -q 'Reachable: yes'; then
        ready=1
        log "gateway respondeu na tentativa ${attempt}/20"
        break
      fi
    fi
    log "gateway ainda aquecendo... tentativa ${attempt}/20"
    sleep 3
  done

  if [ -z "$ready" ]; then
    log "gateway não ficou pronto no tempo esperado"
    openclaw gateway status || true
    journalctl --user -u openclaw-gateway.service -n 120 --no-pager || true
    exit 1
  fi

  openclaw gateway status
}

project_validation() {
  log "validando componentes mínimos do projeto"
  require_cmd openclaw
  require_cmd ollama
  ollama --version
  curl -fsS http://127.0.0.1:11434/api/tags >/dev/null
  openclaw gateway health >/dev/null
  openclaw gateway probe | grep -q 'Reachable: yes'
  python3 - <<PY
import json, os
p=os.path.expanduser('$CONFIG_FILE')
with open(p) as f:
    cfg=json.load(f)
assert cfg.get('gateway', {}).get('mode') == 'local'
assert cfg.get('gateway', {}).get('auth', {}).get('token')
assert cfg.get('gateway', {}).get('bind') == 'loopback'
assert cfg.get('gateway', {}).get('port') == 18789
assert cfg.get('agents', {}).get('defaults', {}).get('workspace')
ollama = cfg.get('models', {}).get('providers', {}).get('ollama', {})
assert ollama.get('baseUrl') == 'http://127.0.0.1:11434'
print('PROJECT_VALIDATION=OK')
PY
}

CURRENT_STEP=$((CURRENT_STEP+1))
step_log "$CURRENT_STEP" "verificando Node.js e npm"
install_node_if_missing

CURRENT_STEP=$((CURRENT_STEP+1))
step_log "$CURRENT_STEP" "verificando instalação do OpenClaw"
install_openclaw_if_missing

CURRENT_STEP=$((CURRENT_STEP+1))
step_log "$CURRENT_STEP" "gravando configuração mínima segura do projeto"
write_project_safe_config

CURRENT_STEP=$((CURRENT_STEP+1))
step_log "$CURRENT_STEP" "subindo e validando o gateway do OpenClaw"
ensure_gateway_ready

CURRENT_STEP=$((CURRENT_STEP+1))
step_log "$CURRENT_STEP" "executando validação final do projeto"
project_validation
log "concluído com sucesso"
