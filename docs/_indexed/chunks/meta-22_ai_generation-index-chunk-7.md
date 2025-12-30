---
doc_id: meta/22_ai_generation/index
chunk_id: meta/22_ai_generation/index#chunk-7
heading_path: ["Windmill AI", "Models"]
chunk_type: prose
tokens: 192
summary: "Models"
---

## Models

Windmill AI supports:
- OpenAI's [models](https://platform.openai.com/docs/models) (o1 currently not supported)
- Azure OpenAI's [models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models)
	- Base URL format: `https://{your-resource-name}.openai.azure.com/openai`
- Anthropic's [models](https://docs.anthropic.com/en/docs/about-claude/models/all-models) (including Claude 3.7 Sonnet in extended thinking mode)
- Mistral's [Codestral](https://mistral.ai/technology/#models)
- DeepSeek's [models](https://api-docs.deepseek.com/quick_start/pricing)
- Google's [Gemini models](https://ai.google.dev/models/gemini)
- Groq's [models](https://console.groq.com/docs/models)
- OpenRouter's [models](https://openrouter.ai/models)
- Together AI's [models](https://docs.together.ai/docs/serverless-models)
- AWS Bedrock's [models](https://aws.amazon.com/bedrock/)
  - Required configuration: AWS region and long term API key
- Custom AI: base URL and API key of any AI provider that is OpenAI API-compatible
  - For Ollama and other local models, select "Custom AI" and provide your Ollama server URL (e.g., `http://localhost:11434/v1` for local Ollama or your custom endpoint)

If you'd like to use a model that isn't in the default dropdown list, you can use any model supported by a provider (like `gpt-4o-2024-05-13` or `claude-3-7-sonnet-20250219`) by simply typing the model name in the model input field and pressing enter.
