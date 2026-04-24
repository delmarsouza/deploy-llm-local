# Telegram no Deploy LLM Local

Este guia cobre o fluxo completo para conectar o OpenClaw ao Telegram usando um bot criado no BotFather.

## O que você vai precisar
- Um bot criado no **@BotFather**
- O **token do bot**
- O **chat/user id** autorizado para uso inicial

## Passo 1 — Criar o bot no BotFather
No Telegram, abra o **@BotFather** e siga este fluxo:

1. Envie `/newbot`
2. Defina o **nome visível** do bot
3. Defina o **username** do bot (precisa terminar em `bot`)
4. Copie o **token** gerado pelo BotFather

### Exemplo
- Nome: `Clawdinho The Mega Bot`
- Username: `ClawdinhoTheMegaBot`

## Passo 2 — Preparar o arquivo de ambiente
Use o exemplo do projeto:

```bash
cp examples/telegram.env.example /tmp/telegram.env
```

Edite o arquivo e preencha:

```env
TELEGRAM_BOT_TOKEN=SEU_TOKEN_AQUI
TELEGRAM_ALLOW_FROM=7680747272
AGENT_NAME=default
```

### Campos
- `TELEGRAM_BOT_TOKEN`: token gerado pelo BotFather
- `TELEGRAM_ALLOW_FROM`: lista de IDs autorizados, separados por vírgula
- `AGENT_NAME`: nome do agente/sessão alvo; use `default` se não tiver motivo para mudar

## Passo 3 — Rodar o setup do Telegram
Com OpenClaw já instalado e funcional:

```bash
bash scripts/setup-telegram.sh /tmp/telegram.env
```

O script faz:
- registro da conta Telegram no OpenClaw
- aplicação das políticas de canal
- aplicação da allowlist
- reinício do gateway
- validação do canal

## Passo 4 — Validar se o Telegram ficou ativo
Rode:

```bash
openclaw channels status --probe
openclaw status --deep
```

### Resultado esperado
Algo próximo de:

```text
Telegram default: enabled, configured, running, ... works
Telegram | OK
```

## Recomendações operacionais
### 1. Comece por DM
Primeiro valide o bot em conversa direta antes de levar para grupos.

### 2. Use allowlist
O padrão recomendado neste projeto é manter acesso restrito via `TELEGRAM_ALLOW_FROM`.

### 3. Não commite token real
Nunca salve token real em:
- `README.md`
- `examples/*.env`
- commits Git

Use sempre um `.env` local fora do versionamento.

### 4. Privacy mode em grupos
Se quiser usar o bot em grupos e reduzir atrito:
1. abra `/mybots` no BotFather
2. selecione o bot
3. vá em **Bot Settings**
4. ajuste **Group Privacy** conforme seu uso

## Troubleshooting rápido
### `401 Unauthorized`
Normalmente significa:
- token copiado errado
- token revogado
- bot recriado e token antigo ainda em uso

### `Cannot find package 'openclaw' ... plugin-runtime-deps`
Isso indica problema no runtime local do plugin Telegram. Corrija o ambiente do OpenClaw antes de testar o token.

### Gateway ok, Telegram não responde
Verifique:

```bash
openclaw gateway status
openclaw channels status --probe
openclaw status --deep
```

## Fluxo recomendado do projeto
1. `scripts/deploy-llm-local.sh`
2. `scripts/setup-openclaw.sh`
3. `scripts/setup-telegram.sh /caminho/do/env`
4. validação com `openclaw status --deep`
