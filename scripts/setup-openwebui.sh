#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker/compose.base.yml"
ENV_FILE="$ROOT_DIR/docker/env/openwebui.env"

log() {
  printf '[setup-openwebui] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "comando obrigatório ausente: $1"
    exit 1
  }
}

require_cmd docker
require_cmd curl

mkdir -p "$ROOT_DIR/docker" "$ROOT_DIR/docker/env"

cat > "$ENV_FILE" <<ENVEOF
OPEN_WEBUI_PORT=3001
OLLAMA_BASE_URL=http://host.docker.internal:11434
ENVEOF

cat > "$COMPOSE_FILE" <<'YMLEOF'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    restart: unless-stopped
    ports:
      - "${OPEN_WEBUI_PORT:-3001}:8080"
    environment:
      OLLAMA_BASE_URL: "${OLLAMA_BASE_URL:-http://host.docker.internal:11434}"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - open-webui-data:/app/backend/data

volumes:
  open-webui-data:
YMLEOF

log "subindo Open WebUI via docker compose"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d --remove-orphans

log "validando container open-webui"
docker ps --filter name=open-webui --format '{{.Names}}' | grep -q '^open-webui$'

health=''
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  status=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' open-webui 2>/dev/null || true)
  if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
    health=1
    break
  fi
  sleep 3
done

if [ -z "$health" ]; then
  log "Container open-webui não ficou saudável/running no tempo esperado"
  docker logs --tail 120 open-webui || true
  exit 1
fi

ok=''
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
  if curl -fsS http://127.0.0.1:3001/health >/dev/null 2>&1 || curl -fsS http://127.0.0.1:3001 >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 3
done

if [ -z "$ok" ]; then
  log "Open WebUI não respondeu em http://127.0.0.1:3001 após aguardar o boot inicial"
  docker logs --tail 120 open-webui || true
  exit 1
fi

log "compose status"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" ps

log "Open WebUI respondendo em http://127.0.0.1:3001"
log "concluído com sucesso"
