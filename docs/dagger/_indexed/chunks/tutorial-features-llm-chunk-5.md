---
doc_id: tutorial/features/llm
chunk_id: tutorial/features/llm#chunk-5
heading_path: ["llm", "Supported models"]
chunk_type: prose
tokens: 96
summary: "Dagger supports a wide range of popular language models, including those from OpenAI, Anthropic a..."
---
Dagger supports a wide range of popular language models, including those from OpenAI, Anthropic and Google. Dagger can access these models either through their respective cloud-based APIs or using local providers like Docker Model Runner or Ollama.

Dagger uses your system's standard environment variables to route LLM requests. Dagger will look for these variables in your environment, or in a `.env` file in the current directory. Learn more about [configuring LLM endpoints in Dagger](/reference/configuration/llm).
