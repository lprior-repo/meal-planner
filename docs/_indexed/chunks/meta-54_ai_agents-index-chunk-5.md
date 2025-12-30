---
doc_id: meta/54_ai_agents/index
chunk_id: meta/54_ai_agents/index#chunk-5
heading_path: ["AI agents", "Chat mode"]
chunk_type: prose
tokens: 327
summary: "Chat mode"
---

## Chat mode

Flows with AI agents can be run in chat mode, which transforms the standard flow interface into a conversational chat UI. This mode is particularly useful for creating interactive AI applications where users can have ongoing conversations with the AI agent.

### Enabling chat mode

To enable chat mode for a flow:
1. Navigate to the flow inputs configuration
2. Toggle the "Chat mode" option on the top right
3. When the flow is run, it will display as a chat interface instead of the standard form interface

<video
	className="border-2 rounded-lg object-cover w-full h-full dark:border-gray-800"
	autoPlay
	loop
	src="/videos/chat_mode.mp4"
/>


### Features

- **Conversational interface**: The flow runs in a chat-like UI where users can send messages and receive responses in a familiar messaging format
- **Multiple conversations**: Users can maintain multiple different conversation threads within the same flow
- **Conversation history**: Each conversation maintains its own history, allowing users to scroll back through previous messages
- **Persistent context**: When using the `messages_context_length` parameter, the AI agent can remember and reference previous messages in the conversation

### Recommended configuration

For optimal chat mode experience, we recommend placing an AI agent step at the end of your flow with both `streaming` and `messages_context_length` enabled. This configuration:
- Enables real-time response streaming for a more interactive chat experience
- Maintains conversation context across multiple messages

### Use cases

Chat mode is ideal for:
- Developing conversational workflows
- Implementing AI assistants with memory
- Building chatbots that can execute actions through tools
