# Hardening

Este guia resume os ajustes recomendados para deixar o ambiente mais seguro depois da homologação inicial.

## 1. Manter o gateway local-only
Se não houver necessidade de expor o painel, mantenha `gateway.bind=loopback`.

## 2. Revisar reverse proxy
Se houver proxy reverso na frente do OpenClaw, configure `gateway.trustedProxies` com os IPs corretos. Se não houver proxy, mantenha local-only.

## 3. Sandboxing
Se optar por modelos menores ou mais permissivos, prefira ativar sandbox para sessões padrão.

## 4. Ferramentas web
Se o ambiente usar modelos pequenos ou menos confiáveis, considere desabilitar ferramentas web para reduzir superfície.

## 5. Atualizações
Revise periodicamente:
- `openclaw update`
- `openclaw status`
- `openclaw security audit`

## 6. Auditoria rápida
Comandos úteis:
```bash
openclaw status
openclaw security audit
openclaw security audit --deep
```
