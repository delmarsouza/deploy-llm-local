# Slack no Deploy LLM Local

Este guia cobre o fluxo completo para conectar o OpenClaw ao Slack usando bot token e app token.

## O que você vai precisar
- Um app criado no Slack
- Um **Bot User OAuth Token**
- Um **App-Level Token**
- Um canal padrão opcional para destino inicial

## Visão rápida
O setup do Slack neste projeto usa o OpenClaw em modo de canal Slack com:
- bot token para API do workspace
- app token para socket mode
- configuração automática via `scripts/setup-slack.sh`

---

## Passo 1 — Criar o app no Slack
No Slack API:
1. acesse `https://api.slack.com/apps`
2. clique em **Create New App**
3. escolha **From scratch**
4. defina o nome do app
5. selecione o workspace

---

## Passo 2 — Ativar Socket Mode
No painel do app:
1. abra **Socket Mode**
2. habilite o recurso
3. gere um **App-Level Token** com permissão adequada

Esse token costuma começar com:
- `xapp-...`

Use esse valor como:
- `SLACK_APP_TOKEN`

---

## Passo 3 — Instalar o bot no workspace
No painel do app:
1. abra **OAuth & Permissions**
2. configure os escopos necessários do bot
3. clique em **Install to Workspace**
4. copie o **Bot User OAuth Token**

Esse token costuma começar com:
- `xoxb-...`

Use esse valor como:
- `SLACK_BOT_TOKEN`

---

## Passo 4 — Preparar o arquivo de ambiente
Use o exemplo do projeto:

```bash
cp examples/slack.env.example /tmp/slack.env
```

Preencha algo como:

```env
SLACK_BOT_TOKEN=xoxb-seu-token-aqui
SLACK_APP_TOKEN=xapp-seu-token-aqui
SLACK_CHANNEL=C1234567890
AGENT_NAME=default
```

### Campos
- `SLACK_BOT_TOKEN`: token do bot do workspace
- `SLACK_APP_TOKEN`: token do app para socket mode
- `SLACK_CHANNEL`: canal padrão opcional
- `AGENT_NAME`: use `default` se não houver necessidade de customização

---

## Passo 5 — Rodar o setup do Slack
Com OpenClaw já instalado e funcional:

```bash
bash scripts/setup-slack.sh /tmp/slack.env
```

O script faz:
- registro da conta Slack no OpenClaw
- aplicação das políticas do canal
- reinício do gateway
- tentativa de validação do canal
- classificação de erros comuns

---

## Passo 6 — Validar o canal
Rode:

```bash
openclaw channels status --probe
openclaw status --deep
```

### Resultado esperado
Algo próximo de:

```text
Slack default: enabled, configured, running ... works
Slack | OK
```

---

## Diagnósticos já tratados pelo projeto
O `setup-slack.sh` já distingue melhor alguns cenários reais:

### `SLACK_AUTH_INVALID`
As credenciais foram rejeitadas pela API do Slack.

Causas mais comuns:
- bot token copiado errado
- app token copiado errado
- token antigo/revogado
- app instalado no workspace errado

### `SLACK_RUNTIME_DEP_MISSING`
O runtime local do canal Slack está sem dependência necessária.

### `GATEWAY_NOT_READY_OR_CRASHED`
O gateway caiu ou não estabilizou durante a subida do canal.

---

## Recomendações
### 1. Não commite token real
Nunca salve token real em:
- `README.md`
- `examples/*.env`
- commits Git

### 2. Comece em um canal de teste
Antes de usar em canal produtivo, valide em um workspace/canal de teste.

### 3. Guarde o ID do canal
O campo `SLACK_CHANNEL` normalmente funciona melhor com o ID do canal, não o nome visual.

---

## Troubleshooting rápido
### `invalid_auth`
Revise:
- `SLACK_BOT_TOKEN`
- `SLACK_APP_TOKEN`
- instalação do app no workspace correto
- escopos do app

### gateway cai ao tentar subir Slack
Verifique:

```bash
openclaw gateway status
openclaw channels status --probe
openclaw status --deep
openclaw channels logs
```

### aviso de `@slack/web-api`
Se aparecer erro ou warning sobre `@slack/web-api`, trate como problema de runtime local do canal Slack e valide o ambiente do OpenClaw antes de concluir que a credencial está errada.

---

## Fluxo recomendado do projeto
1. `scripts/deploy-llm-local.sh`
2. `scripts/setup-openclaw.sh`
3. `scripts/setup-slack.sh /caminho/do/env`
4. validação com `openclaw status --deep`
