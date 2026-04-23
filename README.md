# Deploy LLM Local

Bootstrap prático para subir um ambiente local de IA com GPU NVIDIA, Ollama, Open WebUI e OpenClaw, com opção de canal Telegram ou Slack.

## Objetivo
Entregar um fluxo de instalação simples e reaproveitável para quem quer subir uma stack local de inferência com interface web e agente conversacional.

## Stack da v1
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

## Observações honestas
- O projeto está funcional como base de bootstrap.
- Parte das validações depende do host final ter Docker, NVIDIA e OpenClaw disponíveis.
- Os scripts de canal dependem de credenciais reais no `.env` correspondente.

## Documentação complementar
- `docs/overview.md`
- `docs/hardware-profiles.md`
- `docs/supported-models.md`
- `docs/linux-distros.md`
- `docs/troubleshooting.md`
