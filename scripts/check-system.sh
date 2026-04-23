#!/usr/bin/env bash
set -euo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m"

have_cmd() { command -v "$1" >/dev/null 2>&1; }

human_gib_from_mib() {
  awk -v v="$1" 'BEGIN { printf "%.1f", v/1024 }'
}

echo -e "${BLUE}== Deploy LLM Local :: System Check ==${NC}"

OS_NAME="unknown"
OS_VERSION="unknown"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_NAME="${NAME:-unknown}"
  OS_VERSION="${VERSION_ID:-unknown}"
fi

echo -e "${BLUE}Sistema:${NC} ${OS_NAME} ${OS_VERSION}"

GPU_NAME="not-found"
GPU_VRAM_MIB=0
DRIVER_VER="unknown"
if have_cmd nvidia-smi; then
  IFS=',' read -r GPU_NAME GPU_VRAM_MIB DRIVER_VER < <(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits | head -n1)
  GPU_NAME="$(echo "$GPU_NAME" | xargs)"
  GPU_VRAM_MIB="$(echo "$GPU_VRAM_MIB" | xargs)"
  DRIVER_VER="$(echo "$DRIVER_VER" | xargs)"
fi

MEM_TOTAL_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
MEM_TOTAL_GIB=$(awk -v v="$MEM_TOTAL_KB" 'BEGIN { printf "%.1f", v/1024/1024 }')

DISK_AVAIL_KB=$(df --output=avail /home 2>/dev/null | tail -n1 | xargs)
if [ -z "${DISK_AVAIL_KB:-}" ]; then
  DISK_AVAIL_KB=$(df --output=avail / | tail -n1 | xargs)
fi
DISK_AVAIL_GIB=$(awk -v v="$DISK_AVAIL_KB" 'BEGIN { printf "%.1f", v/1024/1024 }')

if have_cmd nvidia-smi; then
  echo -e "${BLUE}GPU:${NC} ${GPU_NAME}"
  echo -e "${BLUE}VRAM:${NC} $(human_gib_from_mib "$GPU_VRAM_MIB") GiB"
  echo -e "${BLUE}Driver NVIDIA:${NC} ${DRIVER_VER}"
else
  echo -e "${RED}GPU NVIDIA não detectada via nvidia-smi.${NC}"
fi

echo -e "${BLUE}RAM:${NC} ${MEM_TOTAL_GIB} GiB"
echo -e "${BLUE}Disco livre:${NC} ${DISK_AVAIL_GIB} GiB"

PROFILE="UNSUPPORTED"
PROFILE_DESC="Hardware fora do alvo da v1.0"
MODEL_RECO="Nenhum"
DISK_RECO="Ver requisitos mínimos"

if [ "$GPU_VRAM_MIB" -ge 14336 ] && awk -v r="$MEM_TOTAL_GIB" 'BEGIN { exit !(r >= 32) }'; then
  PROFILE="16GB"
  PROFILE_DESC="Perfil 16 GB VRAM / 32–64 GB RAM"
  MODEL_RECO="Qwen2.5 7B Instruct"
  DISK_RECO="80 a 150 GB livres"
elif [ "$GPU_VRAM_MIB" -ge 7168 ] && awk -v r="$MEM_TOTAL_GIB" 'BEGIN { exit !(r >= 16) }'; then
  PROFILE="8GB"
  PROFILE_DESC="Perfil 8 GB VRAM / 16–32 GB RAM"
  MODEL_RECO="Qwen2.5 3B Instruct"
  DISK_RECO="50 a 100 GB livres"
elif [ "$GPU_VRAM_MIB" -ge 5120 ] && awk -v r="$MEM_TOTAL_GIB" 'BEGIN { exit !(r >= 8) }'; then
  PROFILE="6GB"
  PROFILE_DESC="Perfil 6 GB VRAM / 8–16 GB RAM"
  MODEL_RECO="Qwen2.5 1.5B Instruct"
  DISK_RECO="35 a 70 GB livres"
fi

echo
echo -e "${BLUE}Perfil detectado:${NC} ${PROFILE_DESC}"
echo -e "${BLUE}Modelo recomendado:${NC} ${MODEL_RECO}"
echo -e "${BLUE}Faixa de disco sugerida:${NC} ${DISK_RECO}"

echo
if [ "$PROFILE" = "UNSUPPORTED" ]; then
  echo -e "${YELLOW}Resultado:${NC} a máquina não atende um perfil oficial da v1.0 sem ajustes."
else
  echo -e "${GREEN}Resultado:${NC} a máquina atende o perfil ${PROFILE}."
fi
