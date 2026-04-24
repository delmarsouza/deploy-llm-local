#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="$CONFIG_DIR/workspace"
LOG_DIR="$CONFIG_DIR/logs"

log() {
  printf '[setup-openclaw] %s\n' "$*"
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
cfg['gateway'].setdefault('mode', 'local')
cfg['gateway'].setdefault('auth', {})
cfg['gateway']['auth'].setdefault('mode', 'token')
cfg['gateway']['auth'].setdefault('token', secrets.token_hex(24))

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
print(open(p).read())
PY
}

ensure_gateway_best_effort() {
  if systemctl --user list-unit-files | grep -q '^openclaw-gateway.service'; then
    log "reiniciando serviço user do gateway"
    systemctl --user restart openclaw-gateway.service || true
  else
    log "tentando iniciar gateway via CLI"
    openclaw gateway restart || openclaw gateway start || true
  fi

  sleep 5
  openclaw gateway status || true
}

project_validation() {
  log "validando componentes mínimos do projeto"
  require_cmd openclaw
  require_cmd ollama
  ollama --version
  curl -fsS http://127.0.0.1:11434/api/tags >/dev/null
  python3 - <<PY
import json, os, sys
p=os.path.expanduser('$CONFIG_FILE')
with open(p) as f:
    cfg=json.load(f)
assert cfg.get('gateway', {}).get('mode') == 'local'
assert cfg.get('gateway', {}).get('auth', {}).get('token')
assert cfg.get('agents', {}).get('defaults', {}).get('workspace')
ollama = cfg.get('models', {}).get('providers', {}).get('ollama', {})
assert ollama.get('baseUrl') == 'http://127.0.0.1:11434'
print('PROJECT_VALIDATION=OK')
PY
}

install_node_if_missing
install_openclaw_if_missing
write_project_safe_config
ensure_gateway_best_effort
project_validation
log "concluído com sucesso"
