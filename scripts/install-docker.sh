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

install_docker_ubuntu() {
  log "Instalando dependências base do Docker..."
  sudo -n apt-get update
  sudo -n apt-get install -y ca-certificates curl gnupg

  log "Configurando keyring oficial do Docker..."
  sudo -n install -m 0755 -d /etc/apt/keyrings
  sudo -n rm -f /etc/apt/keyrings/docker.gpg
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -n gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo -n chmod a+r /etc/apt/keyrings/docker.gpg

  . /etc/os-release
  CODENAME="${UBUNTU_CODENAME:-${VERSION_CODENAME:-noble}}"
  ARCH="$(dpkg --print-architecture)"

  log "Adicionando repositório oficial do Docker..."
  echo \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" | \
    sudo -n tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "Instalando Docker Engine e plugins..."
  sudo -n apt-get update
  sudo -n apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

post_install() {
  log "Habilitando e iniciando Docker..."
  sudo -n systemctl enable --now docker

  if ! getent group docker >/dev/null; then
    log "Criando grupo docker..."
    sudo -n groupadd docker
  fi

  if ! id -nG "$USER" | grep -qw docker; then
    log "Adicionando usuário $USER ao grupo docker..."
    sudo -n usermod -aG docker "$USER"
    warn "Tu vais precisar encerrar e reabrir a sessão para usar docker sem sudo."
  fi

  ok "Docker instalado e serviço iniciado."
}

validate_install() {
  log "Validando instalação..."
  docker --version || true
  docker compose version || true
  sudo -n systemctl --no-pager --full status docker | sed -n '1,20p' || true
}

main() {
  log "Iniciando instalação do Docker para Ubuntu/Pop!_OS..."
  require_sudo
  install_docker_ubuntu
  post_install
  validate_install
  ok "Etapa install-docker concluída."
}

main "$@"
