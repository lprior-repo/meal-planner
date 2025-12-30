---
doc_id: tutorial/reference/configuration-llm
chunk_id: tutorial/reference/configuration-llm#chunk-7
heading_path: ["configuration-llm", "Ollama"]
chunk_type: mixed
tokens: 42
summary: "1."
---
1. Start Ollama server: `OLLAMA_HOST="0.0.0.0:11434" ollama serve`
2. Pull models: `ollama pull qwen2.5-coder:14b`
3. Get host IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
4. Configure:

```bash
OPENAI_BASE_URL=http://YOUR-IP:11434/v1/
OPENAI_MODEL=qwen2.5-coder:14b
```
