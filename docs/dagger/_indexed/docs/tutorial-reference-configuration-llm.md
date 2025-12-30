---
id: tutorial/reference/configuration-llm
title: "LLM Providers Configuration"
category: tutorial
tags: ["api", "tutorial", "ai", "docker", "llm"]
---

# LLM Providers Configuration

> **Context**: Dagger supports a wide range of Large Language Models (LLMs). Dagger uses standard environment variables to route LLM requests.


Dagger supports a wide range of Large Language Models (LLMs). Dagger uses standard environment variables to route LLM requests.

## Anthropic

- `ANTHROPIC_API_KEY`: required
- `ANTHROPIC_MODEL`: optional, defaults to `"claude-sonnet-4-5"`

## OpenAI

- `OPENAI_API_KEY`: required
- `OPENAI_MODEL`: optional, defaults to `"gpt-4o"`
- `OPENAI_BASE_URL`: optional, for alternative OpenAI-compatible endpoints
- `OPENAI_AZURE_VERSION`: for Azure's API to OpenAI

## Google Gemini

- `GEMINI_API_KEY`: required
- `GEMINI_MODEL`: optional, defaults to `"gemini-2.0-flash"`

## Azure OpenAI Service

- `OPENAI_BASE_URL`: required (e.g., `"https://your-azure-openai-resource.cognitiveservices.azure.com"`)
- `OPENAI_API_KEY`: required
- `OPENAI_MODEL`: optional
- `OPENAI_AZURE_VERSION`: optional

## Docker Model Runner

```bash
OPENAI_BASE_URL=http://model-runner.docker.internal/engines/v1/
OPENAI_MODEL=index.docker.io/ai/qwen2.5:7B-F16
OPENAI_DISABLE_STREAMING=true
```

## Ollama

1. Start Ollama server: `OLLAMA_HOST="0.0.0.0:11434" ollama serve`
2. Pull models: `ollama pull qwen2.5-coder:14b`
3. Get host IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
4. Configure:

```bash
OPENAI_BASE_URL=http://YOUR-IP:11434/v1/
OPENAI_MODEL=qwen2.5-coder:14b
```

## See Also

- [Documentation Overview](./COMPASS.md)
