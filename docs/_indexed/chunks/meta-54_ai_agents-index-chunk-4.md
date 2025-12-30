---
doc_id: meta/54_ai_agents/index
chunk_id: meta/54_ai_agents/index#chunk-4
heading_path: ["AI agents", "Input parameters"]
chunk_type: code
tokens: 709
summary: "Input parameters"
---

## Input parameters

### Required parameters

#### user_message (string)
The main input message or prompt that will be sent to the AI model. This can include static text, dynamic content from previous flow steps, or templated strings with variable substitution.

#### system_prompt (string) 
The system prompt that defines the AI's role, behavior, and context. This helps guide the model's responses and ensures consistent behavior across interactions.

### Optional parameters

#### output_type (text | image)
Specifies the type of output the AI should generate:
- `text` - Generate text responses (default).
- `image` - Generate image outputs (supported by OpenAI, Google AI (Gemini), and OpenRouter). Requires an [S3 object storage](./meta-38_object_storage_in_windmill-index.md) to be configured at the workspace level.

#### output_schema (json-schema)
Define a JSON schema that the AI agent will follow for its response format. This ensures structured, predictable outputs that can be easily processed by subsequent flow steps.

#### messages_context_length (number)
Specifies the number of previous messages to include as context for the AI agent. This enables the agent to maintain conversation history and remember past interactions. When set, the agent will have access to the specified number of previous messages from the conversation, allowing for more contextual and coherent responses across multiple interactions.

#### Using messages_context_length with webhooks

When using `messages_context_length` via webhook, you must include a `memory_id` query parameter in your request. The `memory_id` must be a 32-character UUID that uniquely identifies the conversation context. This allows the AI agent to maintain message history across webhook calls.

Example webhook URL:
```yaml
https://your-windmill-instance/api/w/your-workspace/jobs/run_wait_result/f/your-flow?memory_id=550e8400e29b41d4a716446655440000
```

#### streaming (optional)

Whether to stream the progress of the AI agent.
The stream will contain json payloads separated by newlines. The payloads can be of the following types:

```json
{
	"type": "token_delta", // sent everytime the AI generates a new token
	"content": "string",
}
```

```json
{
	"type": "tool_call", // sent when the tool call is started
	"call_id": "string",
    "function_name": "string",
    "function_arguments": "string",
}
```

```json
{
	"type": "tool_call_arguments", // sent all arguments have been received
	"call_id": "string",
    "function_name": "string",
    "function_arguments": "string",
}
```

```json
{
	"type": "tool_execution", // sent when the tool job is started
	"call_id": "string",
    "function_name": "string",
}
```

```json
{
	"type": "tool_result", // sent when the tool job is completed
	"call_id": "string",
    "function_name": "string",
    "result": "string",
    "success": true, // whether the tool job completed successfully
}
```

The final result of the step will contain an additional field `wm_stream` with the complete stream.

You can use the [SSE stream webhooks](./meta-4_webhooks-index.md#sse-stream-webhooks) to get the stream. 
The `new_result_stream` field of an SSE event can contain multiple payloads at a time, make sure to split on line breaks. 
Only complete payloads are streamed, you do not need to handle partial JSON.

#### user_images (optional)
Allows you to pass images as input to the AI model for analysis, processing, or context. The AI can analyze the image content and respond accordingly. Requires an [S3 object storage](./meta-38_object_storage_in_windmill-index.md) to be configured at the workspace level.

#### max_completion_tokens (number)
Controls the maximum number of tokens the AI can generate in its response. This helps manage costs and ensures responses stay within desired length limits.

#### temperature (number)
Controls randomness in text generation:
- `0.0` - Deterministic, focused responses
- `2.0` - Maximum creativity and randomness
- Default values typically range from 0.1 to 1.0
