#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
TOTAL_STEPS=5
CURRENT_STEP=0
SELECTED_PROFILE=""

log() {
  printf '[deploy-llm-local] %s\n' "$*"
}

step_log() {
  printf '[deploy-llm-local] [%s/%s] %s\n' "$1" "$TOTAL_STEPS" "$2"
}

require_script() {
  local script="$1"
  if [ ! -x "$SCRIPTS_DIR/$script" ]; then
    log "script obrigatório ausente ou sem permissão de execução: $script"
    exit 1
  fi
}

show_troubleshooting_hint() {
  cat <<'EOF'
[deploy-llm-local] se parecer parado por muito tempo, abra outro terminal e rode:
[deploy-llm-local]   docker ps
[deploy-llm-local]   openclaw gateway status || true
[deploy-llm-local]   bash scripts/healthcheck.sh || true
EOF
}

run_step() {
  local label="$1"
  local script="$2"
  CURRENT_STEP=$((CURRENT_STEP+1))
  step_log "$CURRENT_STEP" "$label"

  case "$script" in
    setup-ollama.sh)
      log "esta etapa pode levar alguns minutos, dependendo de downloads e do estado do host"
      ;;
    setup-openwebui.sh)
      log "o Open WebUI pode baixar imagem Docker grande na primeira execução; aguarde se o terminal parecer parado"
      show_troubleshooting_hint
      ;;
  esac

  "$SCRIPTS_DIR/$script"
  log "etapa concluída: $label"
}

usage() {
  cat <<EOF
Uso:
  bash scripts/deploy-llm-local.sh [--profile 16gb|8gb|6gb]

Também aceita:
  DEPLOY_LLM_PROFILE=16gb bash scripts/deploy-llm-local.sh
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --profile)
        [ "$#" -ge 2 ] || { log "faltou valor para --profile"; exit 1; }
        SELECTED_PROFILE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        log "argumento não reconhecido: $1"
        usage
        exit 1
        ;;
    esac
  done
}

select_profile() {
  local profile=""
  if [ -n "$SELECTED_PROFILE" ]; then
    profile="$SELECTED_PROFILE"
  elif [ -n "${DEPLOY_LLM_PROFILE:-}" ]; then
    profile="$DEPLOY_LLM_PROFILE"
  else
    printf '\nSelecione o perfil de hardware:\n'
    printf '  1) 16gb\n'
    printf '  2) 8gb\n'
    printf '  3) 6gb\n'
    printf 'Escolha [1-3]: '
    read -r opt
    case "$opt" in
      1) profile='16gb' ;;
      2) profile='8gb' ;;
      3) profile='6gb' ;;
      *) log 'perfil inválido'; exit 1 ;;
    esac
  fi

  case "$profile" in
    16gb|8gb|6gb) ;;
    *) log "perfil inválido: $profile"; exit 1 ;;
  esac

  printf '%s' "$profile"
}

main() {
  parse_args "$@"

  require_script check-system.sh
  require_script install-docker.sh
  require_script install-nvidia-toolkit.sh
  require_script setup-ollama.sh
  require_script setup-openwebui.sh

  local profile
  profile="$(select_profile)"
  export DEPLOY_LLM_PROFILE="$profile"

  log "perfil selecionado: $profile"
  log "bootstrap iniciado; etapas totais: $TOTAL_STEPS"

  run_step 'checagem do sistema' 'check-system.sh'
  run_step 'instalação/validação do Docker' 'install-docker.sh'
  run_step 'instalação/validação do NVIDIA Container Toolkit' 'install-nvidia-toolkit.sh'
  run_step 'instalação/validação do Ollama' 'setup-ollama.sh'
  run_step 'instalação/validação do Open WebUI' 'setup-openwebui.sh'

  log "bootstrap base + interface concluídos com sucesso para o perfil $profile"
  log "próximos passos recomendados:"
  log "  1) bash scripts/setup-openclaw.sh"
  log "  2) bash scripts/healthcheck.sh || true"
  log "  3) abrir http://127.0.0.1:3001 no navegador"
  log "  4) opcional: integração Telegram"
}

main "$@"
