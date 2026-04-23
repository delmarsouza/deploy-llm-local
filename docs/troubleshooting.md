# Troubleshooting

## 1. Docker não encontrado
Sintoma:
- `docker: command not found`

Ação:
- rode `scripts/install-docker.sh`
- reabra a sessão se o usuário foi adicionado ao grupo `docker`

## 2. GPU NVIDIA não detectada
Sintoma:
- `nvidia-smi` falha

Ação:
- instale ou corrija o driver NVIDIA
- confirme com `nvidia-smi`

## 3. Docker sem acesso à GPU
Sintoma:
- container CUDA não enxerga GPU

Ação:
- rode `scripts/install-nvidia-toolkit.sh`
- reinicie o Docker
- teste com:
  `docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi`

## 4. Ollama não responde
Sintoma:
- `http://127.0.0.1:11434` não responde

Ação:
- rode `scripts/setup-ollama.sh`
- confira `ollama --version`
- confira `systemctl status ollama`

## 5. Open WebUI não sobe
Sintoma:
- porta 3000 não responde

Ação:
- confirme se o host final realmente tem Docker acessível
- confira os arquivos em `docker/env/` e `docker/compose*.yml`
- rode `bash scripts/setup-openwebui.sh 16gb`
- se falhar, inspecione o status e logs do compose
- confirme se o Ollama está acessível em `127.0.0.1:11434` ou via `host.docker.internal`

## 6. OpenClaw não responde
Sintoma:
- gateway não responde em `127.0.0.1:18789`

Ação:
- confira `openclaw status`
- confira `openclaw gateway status`
- reinicie com `openclaw gateway restart`

## 7. Telegram ou Slack não conectam
Sintoma:
- canal aparece com erro ou não autentica

Ação:
- revise o `.env` correspondente em `examples/`
- confirme token real
- rode o script do canal novamente
- valide com `openclaw status`
