#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

log() {
  printf '[deploy-llm-local] %s\n' "$*"
}

require_script() {
  local script="$1"
  if [ ! -x "$SCRIPTS_DIR/$script" ]; then
    log "script obrigatório ausente ou sem permissão de execução: $script"
    exit 1
  fi
}

run_step() {
  local label="$1"
  local script="$2"
  log "executando etapa: $label"
  "$SCRIPTS_DIR/$script"
}

select_profile() {
  local profile=""
  if [ -n "${DEPLOY_LLM_PROFILE:-}" ]; then
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
  require_script check-system.sh
  require_script install-docker.sh
  require_script install-nvidia-toolkit.sh
  require_script setup-ollama.sh
  require_script setup-openwebui.sh

  local profile
  profile="$(select_profile)"
  log "perfil selecionado: $profile"

  run_step 'checagem do sistema' 'check-system.sh'
  run_step 'instalação/validação do Docker' 'install-docker.sh'
  run_step 'instalação/validação do NVIDIA Container Toolkit' 'install-nvidia-toolkit.sh'
  run_step 'instalação/validação do Ollama' 'setup-ollama.sh'
  run_step 'instalação/validação do Open WebUI' 'setup-openwebui.sh'

  log "bootstrap base + interface concluídos com sucesso para o perfil $profile"
  log "próximos passos: setup-openclaw.sh e integração Telegram/Slack"
}

main "$@"
