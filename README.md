# Deploy LLM Local

Bootstrap prático para subir LLM local com Docker, UI web e bot pronto para Telegram ou Slack, escalado por perfil de hardware.

## Objetivo
Criar um ambiente local pronto para execução de LLMs com GPU NVIDIA, usando Docker, Open WebUI e OpenClaw, com opções de bot para Telegram ou Slack.

## Perfis suportados
- 16 GB VRAM / 32–64 GB RAM
- 8 GB VRAM / 16–32 GB RAM
- 6 GB VRAM / 8–16 GB RAM

## Stack v1.0
- Docker
- Docker Compose
- NVIDIA Container Toolkit
- Ollama
- Open WebUI
- OpenClaw

## Entregas da v1.0
- script único de bootstrap
- configuração por perfil de hardware
- interface web local
- bot pronto para Telegram ou Slack
- documentação prática

## Estrutura
Veja `docs/overview.md` e os diretórios `scripts/`, `docker/` e `examples/`.
