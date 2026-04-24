# Deploy LLM Local

## Pré-requisitos
- Acesse em (docs/prerequisites.md) para verificar os requisitos do host, dependências de tempo de execução e perfis de hardware.

Bootstrap prático para subir um ambiente local de IA com GPU NVIDIA, Ollama, Open WebUI e OpenClaw, com opção de canal Telegram ou Slack.

## Objetivo
Entregar fluxo de instalação simples e reaproveitável para quem quer subir uma stack local de inferência com interface web e agente conversacional.

## Stack da v1

## Status atual
- **v1.0.1 homologada em ambiente real assistido**
- Bootstrap funcional para Pop!_OS/Ubuntu com GPU NVIDIA
- Fluxo validado com Docker, NVIDIA, Ollama, Open WebUI e OpenClaw
- Hardening inicial do OpenClaw aplicado

- Docker
- Docker Compose
- NVIDIA Container Toolkit
- Ollama
- Open WebUI
- OpenClaw
- Telegram ou Slack

## Perfis suportados
- **16 GB VRAM / 32–64 GB RAM**
- **8 GB VRAM / 16–32 GB RAM**
- **6 GB VRAM / 8–16 GB RAM**

## Scripts disponíveis
- `scripts/check-system.sh`
- `scripts/install-docker.sh`
- `scripts/install-nvidia-toolkit.sh`
- `scripts/setup-ollama.sh`
- `scripts/setup-openwebui.sh`
- `scripts/setup-openclaw.sh`
- `scripts/setup-telegram.sh`
- `scripts/setup-slack.sh`
- `scripts/deploy-llm-local.sh`
- `scripts/harden-openclaw.sh`
- `scripts/healthcheck.sh`

## Fluxo recomendado
### Bootstrap principal
```bash
bash scripts/deploy-llm-local.sh --profile 16gb
```

### Bootstrap com Telegram
```bash
bash scripts/deploy-llm-local.sh \
  --profile 16gb \
  --channel telegram \
  --channel-env examples/telegram.env.example
```

### Bootstrap com Slack
```bash
bash scripts/deploy-llm-local.sh \
  --profile 16gb \
  --channel slack \
  --channel-env examples/slack.env.example
```

## Arquivos importantes
- `docker/env/*.env` → parâmetros por perfil
- `docker/compose*.yml` → stack do Open WebUI por perfil
- `examples/telegram.env.example` → exemplo de canal Telegram
- `examples/slack.env.example` → exemplo de canal Slack
- `examples/openclaw.env.example` → exemplo de integração local

## Observações
- O projeto está funcional como base de bootstrap.
- Parte das validações depende do host final ter Docker, NVIDIA e OpenClaw disponíveis.
- Os scripts de canal dependem de credenciais `.env` correspondente.

## Documentação complementar
- `docs/overview.md`
- `docs/hardware-profiles.md`
- `docs/supported-models.md`
- `docs/linux-distros.md`
- `docs/troubleshooting.md`
- `docs/hardening.md`


## Verificação rápida de saúde
```bash
bash scripts/healthcheck.sh
```
