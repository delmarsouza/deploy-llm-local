# Prerequisites

## Supported host for v1.0
- Ubuntu 24.04 LTS (official)
- Pop!_OS 24.04 (validated secondary target)

## Minimum base packages expected on host
- bash
- curl
- git
- jq
- ca-certificates
- lsb-release
- gpg
- systemd / systemctl
- tar
- gzip

## Language/runtime prerequisites
- python3
- python3-pip
- node
- npm

## Infrastructure prerequisites
- Docker Engine
- Docker Compose plugin
- NVIDIA driver correctly installed
- NVIDIA Container Toolkit

## Hardware assumptions
### 16 GB VRAM profile
- NVIDIA GPU with 16 GB VRAM
- 32 GB to 64 GB RAM
- 80 GB to 150 GB free disk

### 8 GB VRAM profile
- NVIDIA GPU with 8 GB VRAM
- 16 GB to 32 GB RAM
- 50 GB to 100 GB free disk

### 6 GB VRAM profile
- NVIDIA GPU with 6 GB VRAM
- 8 GB to 16 GB RAM
- 35 GB to 70 GB free disk

## Network assumptions
Required for first bootstrap:
- internet access for package installation
- internet access for pulling Docker images
- internet access for model download

## Notes
The project should bootstrap the application stack, but the host still needs a sane Linux base with package management, Python, Node, Docker support and NVIDIA driver support available.
