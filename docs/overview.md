# Overview

Deploy LLM Local é um projeto de bootstrap para criar uma stack local de IA com foco em execução prática, reaproveitamento e adaptação por perfil de hardware.

## O que ele sobe
- base de diagnóstico de hardware
- Docker e Docker Compose
- NVIDIA Container Toolkit
- Ollama
- Open WebUI
- OpenClaw
- canal Telegram ou Slack (quando configurado)

## Como pensar o fluxo
1. detectar perfil da máquina
2. preparar Docker
3. preparar runtime NVIDIA
4. subir Ollama
5. subir Open WebUI
6. validar OpenClaw
7. configurar canal opcional

## Perfil de uso
Esse projeto serve para:
- laboratório local de IA
- POC de assistente privado
- interface web local para modelos
- base de bot integrado com OpenClaw

## Estado da v1
A v1 entrega a maior parte do fluxo de bootstrap com scripts separados e um orquestrador principal. O fechamento da experiência depende de credenciais reais para os canais e do host final ter os requisitos instalados corretamente.
