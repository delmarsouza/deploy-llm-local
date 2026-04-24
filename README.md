# Deploy LLM Local

Bootstrap prático para subir uma stack local de IA com GPU NVIDIA, interface web e agente conversacional em Linux.

A proposta do projeto é reduzir atrito de instalação e deixar um ambiente pronto e funcional com:
- **Ollama** para inferência local
- **Open WebUI** para interface web
- **OpenClaw** para agente, automação e canais
- **Telegram ou Slack** como camada opcional de conversa

---

## O que este projeto resolve

Subir um ambiente local de LLM com GPU, o que costuma trazer uma série de dificuldades como:
- Docker mal configurado
- NVIDIA Container Toolkit inconsistente
- Ollama instalado de um jeito, UI de outro
- OpenClaw sem gateway funcional
- canais de chat quebrando na hora final

Este repositório organiza isso em um fluxo único, com scripts separados por etapa e um bootstrap principal para acelerar a implantação.

---

## Stack da v1

- Docker
- Docker Compose
- NVIDIA Container Toolkit
- Ollama
- Open WebUI
- OpenClaw
- Telegram ou Slack

---

## v1.0 validada

A v1.0 do **Deploy LLM Local** foi validada em host real com foco em implantação prática de uma stack local de IA com GPU NVIDIA, interface web e agente conversacional.

### O que entra na v1.0
- Docker
- NVIDIA Container Toolkit
- Ollama
- Open WebUI
- OpenClaw
- canal Telegram validado em ambiente real
- suporte prático para:
  - Ubuntu 24.04 LTS
  - Pop!_OS 24.04
- perfis de hardware:
  - 6 GB VRAM
  - 8 GB VRAM
  - 16 GB VRAM

### O que foi validado na prática
- bootstrap base funcional
- instalação limpa e consistente do Docker
- instalação limpa do NVIDIA Container Toolkit
- Ollama respondendo localmente
- Open WebUI subindo e ficando healthy
- OpenClaw com gateway funcional
- Telegram ativo e operacional

### O que não entra ainda como homologado
- Slack validado ponta a ponta em ambiente real
- suporte oficial a outros canais além de Telegram
- suporte oficial a hosts sem NVIDIA
- suporte amplo a distribuições fora do alvo principal
- hardening completo do runtime de plugins/canais do OpenClaw

### Limitações conhecidas nesta versão
- o primeiro bootstrap pode baixar imagens e dependências pesadas
- o tempo de instalação varia bastante conforme rede, disco e GPU
- Slack já tem script e documentação, mas ainda não está homologado como canal validado de ponta a ponta nesta v1
- canais do OpenClaw ainda merecem hardening adicional em cenários de reinstalação/rebuild de runtime

### Próximos passos
- homologar Slack em ambiente real
- reforçar o healthcheck da stack
- fortalecimento do runtime de plugins/canais do OpenClaw
- ampliar troubleshooting operacional
- consolidar a apresentação comercial/técnica do projeto

---

## Status atual

### Validado em ambiente real
- **v1.0.1 homologada em host real assistido**
- Bootstrap funcional em **Pop!_OS 24.04**
- Fluxo base validado em **Ubuntu 24.04 LTS** como alvo oficial do projeto
- Fluxo validado com:
  - Docker
  - NVIDIA Container Toolkit
  - Ollama
  - Open WebUI
  - OpenClaw
  - Telegram

### O que já foi provado na prática
- instalação limpa do Docker com ajuste de consistência
- instalação limpa do NVIDIA Container Toolkit
- Ollama funcional e respondendo localmente
- Open WebUI subindo e ficando operacional
- OpenClaw com gateway funcional
- Telegram ativo com validação real do canal

---

## Perfis suportados

- **16 GB VRAM / 32–64 GB RAM**
- **8 GB VRAM / 16–32 GB RAM**
- **6 GB VRAM / 8–16 GB RAM**

---

## Público-alvo

Este projeto é útil para quem quer:
- montar laboratório local de IA com GPU NVIDIA
- demonstrar uma stack privada de IA para clientes
- acelerar POCs de assistentes internos
- ter interface web + agente + canal de chat em uma base só
- padronizar bootstrap em workstations e servidores Linux

---

## Pré-requisitos

Consulte:
- `docs/prerequisites.md`

Lá estão os requisitos de host, dependências de tempo de execução e notas de hardware.

---

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

---

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

### Configuração manual do Telegram após bootstrap
```bash
cp examples/telegram.env.example /tmp/telegram.env
# preencha o token do BotFather e a allowlist
bash scripts/setup-telegram.sh /tmp/telegram.env
```

Consulte `docs/telegram.md` para o fluxo completo do BotFather, criação do bot, token e validação final.

### Bootstrap com Slack
```bash
bash scripts/deploy-llm-local.sh \
  --profile 16gb \
  --channel slack \
  --channel-env examples/slack.env.example
```

### Configuração manual do Slack após bootstrap
```bash
cp examples/slack.env.example /tmp/slack.env
# preencha o bot token, app token e o canal padrão
bash scripts/setup-slack.sh /tmp/slack.env
```

Consulte `docs/slack.md` para o fluxo completo de criação do app, socket mode, tokens e validação final.

---

## Arquivos importantes

- `docker/env/*.env` → parâmetros por perfil
- `docker/compose*.yml` → stack do Open WebUI por perfil
- `examples/telegram.env.example` → exemplo de canal Telegram
- `docs/telegram.md` → passo a passo do BotFather, token, allowlist e validação do Telegram
- `examples/slack.env.example` → exemplo de canal Slack
- `docs/slack.md` → passo a passo de criação do app, tokens, socket mode e validação do Slack
- `examples/openclaw.env.example` → exemplo de integração local

---

## Verificação rápida de saúde

```bash
bash scripts/healthcheck.sh
```

---

## Documentação complementar

- `docs/overview.md`
- `docs/hardware-profiles.md`
- `docs/supported-models.md`
- `docs/linux-distros.md`
- `docs/troubleshooting.md`
- `docs/hardening.md`
- `docs/telegram.md`
- `docs/slack.md`

---

## Observações

- O projeto já está funcional como base de bootstrap real.
- Parte das validações depende do host final ter GPU NVIDIA, Docker e conectividade adequados.
- Os scripts de canal dependem de credenciais locais em `.env`.
- **Nunca commite token real** de Telegram, Slack ou qualquer outro canal.

---

## Roadmap curto

### Fechado
- bootstrap base
- Open WebUI
- OpenClaw
- Telegram
- documentação inicial do Telegram

### Próximos passos naturais
- consolidar Slack
- reforçar troubleshooting
- melhorar narrativa comercial da v1
- empacotar melhor o projeto como peça de portfólio
