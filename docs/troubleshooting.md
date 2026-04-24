# Troubleshooting

Guia prático para os problemas mais comuns do `deploy-llm-local`, com foco nos erros que já apareceram em validação real de host.

---

## 1. Docker não encontrado

### Sintoma
- `docker: command not found`

### Ação
- rode `scripts/install-docker.sh`
- reabra a sessão se o usuário foi adicionado ao grupo `docker`
- valide com:

```bash
docker --version
docker ps
```

---

## 2. GPU NVIDIA não detectada

### Sintoma
- `nvidia-smi` falha
- GPU não aparece no host

### Ação
- instale ou corrija o driver NVIDIA
- confirme com:

```bash
nvidia-smi
```

Se o host não enxerga a GPU, o restante da stack com aceleração não vai fechar corretamente.

---

## 3. Docker sem acesso à GPU

### Sintoma
- containers CUDA não enxergam GPU
- Open WebUI / workloads GPU ficam sem aceleração

### Ação
- rode `scripts/install-nvidia-toolkit.sh`
- reinicie o Docker
- teste com:

```bash
docker run --rm --gpus all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

---

## 4. Ollama não responde

### Sintoma
- `http://127.0.0.1:11434` não responde
- `ollama --version` falha

### Ação
- rode `scripts/setup-ollama.sh`
- valide com:

```bash
ollama --version
curl http://127.0.0.1:11434/api/tags
```

Se necessário, confira o serviço:

```bash
systemctl status ollama
```

---

## 5. Open WebUI sobe, mas o script marca erro

### Sintoma
- container do Open WebUI está no ar
- porta responde
- mas o script termina com `code 1`

### Causa real já observada
O serviço pode estar saudável e o erro vir apenas de uma checagem final de `docker compose` executada fora do contexto correto.

### Ação
Valide o que realmente importa:

```bash
docker ps
curl http://127.0.0.1:3001
```

Se o container estiver `healthy` e a porta responder, o problema provavelmente está na validação final do script, não no Open WebUI em si.

---

## 6. Open WebUI não sobe

### Sintoma
- porta `3001` não responde
- container não fica estável

### Ação
- rode `bash scripts/setup-openwebui.sh`
- valide:

```bash
docker ps
docker logs open-webui --tail 200
curl http://127.0.0.1:3001
```

Também confirme se o Ollama está acessível em:
- `127.0.0.1:11434`
- ou via `host.docker.internal`

---

## 7. OpenClaw instalado, mas gateway não responde

### Sintoma
- `openclaw` instalado
- config existe
- mas `127.0.0.1:18789` não responde

### Causa real já observada
O OpenClaw pode estar instalado, mas o **gateway service** ainda não foi instalado/habilitado corretamente.

### Ação
Valide com:

```bash
openclaw gateway status
openclaw gateway health
openclaw gateway probe
```

Se estiver desabilitado, instale/habilite o service:

```bash
openclaw gateway install
openclaw gateway start
```

Se necessário:

```bash
systemctl --user status openclaw-gateway.service --no-pager
```

---

## 8. OpenClaw parece rodando, mas ainda não está pronto

### Sintoma
- service aparece como ativo
- mas probe falha logo após o start

### Causa real já observada
O gateway pode precisar de alguns segundos extras para instalar dependências internas e ficar realmente pronto.

### Ação
Aguarde e valide de novo:

```bash
openclaw gateway status
openclaw gateway probe
openclaw gateway health
```

Se o `health` e o `probe` ficarem verdes depois de alguns segundos, o problema era readiness e não falha de instalação.

---

## 9. Telegram configurado, mas dá `401 Unauthorized`

### Sintoma
- o canal Telegram aparece configurado
- o gateway tenta subir o provider
- mas as chamadas falham com `401 Unauthorized`

### Causa mais comum
- token copiado errado
- token revogado
- token antigo de um bot recriado

### Ação
No BotFather:
1. abra `/mybots`
2. selecione o bot
3. vá em **API Token**
4. copie novamente o token atual

Depois reaplique:

```bash
bash scripts/setup-telegram.sh /caminho/do/env
```

Valide com:

```bash
openclaw channels status --probe
openclaw status --deep
```

---

## 10. Telegram quebra com erro de `plugin-runtime-deps`

### Sintoma
Erro parecido com:

```text
Cannot find package 'openclaw' imported from ... plugin-runtime-deps ...
```

### Causa real já observada
O runtime local do plugin Telegram pode ficar sem uma dependência necessária no diretório de `plugin-runtime-deps`.

### Ação
Inspecione o diretório do runtime e confirme a dependência faltante.

Se necessário, reinstale a dependência no runtime afetado e reinicie o gateway.

Depois valide novamente com:

```bash
openclaw channels status --probe
openclaw status --deep
```

---

## 11. Telegram aparece configurado, mas não fica saudável

### Sintoma
- conta Telegram existe
- token aparece configurado
- mas o status não fica OK

### Ação
Use estas checagens em sequência:

```bash
openclaw channels list
openclaw channels status --probe
openclaw status --deep
openclaw channels logs
```

Essa sequência ajuda a separar:
- erro de credencial
- erro de runtime
- erro de provider
- erro de gateway

---

## 12. Branch local em `master`, remoto em `main`

### Sintoma
- commit local existe
- push para `main` falha
- histórico fica confuso

### Causa real já observada
O branch local pode estar em `master` enquanto o repositório remoto usa `main` como branch principal.

### Ação
Valide com:

```bash
git branch -vv
git remote show origin
```

Se necessário, empurre explicitamente para `main`:

```bash
git push origin HEAD:main
```

Se houver arquivo local pendente atrapalhando o rebase, stash só o arquivo problemático antes de reconciliar.

---

## 13. Rebase bloqueado por arquivo local pendente

### Sintoma
- `git rebase origin/main` falha
- mensagem de unstaged changes

### Ação
Se existir um arquivo local que não deve entrar no commit atual, stash apenas ele:

```bash
git stash push -m "temp-file-before-rebase" -- caminho/do/arquivo
```

Depois:

```bash
git rebase origin/main
git push origin HEAD:main
git stash pop
```

---

## 14. Ordem prática de validação do stack

Quando der problema, valide nesta ordem:

### 1. Host e GPU
```bash
nvidia-smi
```

### 2. Docker
```bash
docker ps
```

### 3. Ollama
```bash
curl http://127.0.0.1:11434/api/tags
```

### 4. Open WebUI
```bash
curl http://127.0.0.1:3001
```

### 5. OpenClaw gateway
```bash
openclaw gateway status
openclaw gateway probe
openclaw gateway health
```

### 6. Canais
```bash
openclaw channels status --probe
openclaw status --deep
```

---

## 15. Regra de ouro

Antes de concluir que “quebrou tudo”, descubra em que camada o problema está:
- host
- Docker
- GPU
- Ollama
- Open WebUI
- OpenClaw gateway
- plugin/canal
- credencial

No projeto, isso evita gastar tempo corrigindo a camada errada.
