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
    exit 1
  fi
}

require_nvidia() {
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    err "nvidia-smi não encontrado. Instala o driver NVIDIA antes de seguir."
    exit 1
  fi
  log "Validando driver NVIDIA..."
  nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
}

install_toolkit_ubuntu() {
  log "Instalando dependências do NVIDIA Container Toolkit..."
  sudo -n apt-get update
  sudo -n apt-get install -y curl gpg ca-certificates

  log "Configurando repositório do NVIDIA Container Toolkit..."
  sudo -n rm -f /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
    sudo -n gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo -n tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null

  sudo -n apt-get update
  sudo -n apt-get install -y nvidia-container-toolkit
}

configure_docker_runtime() {
  log "Configurando runtime NVIDIA no Docker..."
  sudo -n nvidia-ctk runtime configure --runtime=docker
  sudo -n systemctl restart docker
}

validate_runtime() {
  log "Validando acesso da GPU via Docker..."
  sudo -n docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
  ok "NVIDIA Container Toolkit instalado e funcional."
}

main() {
  log "Iniciando instalação do NVIDIA Container Toolkit..."
  require_sudo
  require_nvidia
  install_toolkit_ubuntu
  configure_docker_runtime
  validate_runtime
}

main "$@"
