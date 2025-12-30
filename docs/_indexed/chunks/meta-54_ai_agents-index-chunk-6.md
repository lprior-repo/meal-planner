---
doc_id: meta/54_ai_agents/index
chunk_id: meta/54_ai_agents/index#chunk-6
heading_path: ["AI agents", "Output"]
chunk_type: prose
tokens: 221
summary: "Output"
---

## Output

The AI Agent step returns an object with two keys:

### output
Contains the content of the final response from the AI agent:
- Text output:
    - **When no output schema is specified**: Returns the last message content, which can be a string or an array containing strings.
    - **When an output schema is specified**: Returns the structured output conforming to the defined JSON schema.
- Image output:
    - Returns the S3 object of the image

This is typically what you'll use in subsequent flow steps when you need the AI's final answer or result.

#### messages
Only in text output mode, contains the complete conversation history, including:
- User input messages
- Assistant intermediate outputs
- Tool calls made by the AI
- Tool execution results

The `messages` array provides full visibility into the AI's reasoning process and tool usage, which can be useful for debugging, logging, or understanding how the AI reached its conclusion.

#### wm_stream (optional)

Only included in streaming mode, contains the complete stream.
