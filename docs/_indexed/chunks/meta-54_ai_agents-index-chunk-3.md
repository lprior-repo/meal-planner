---
doc_id: meta/54_ai_agents/index
chunk_id: meta/54_ai_agents/index#chunk-3
heading_path: ["AI agents", "Script tools"]
chunk_type: prose
tokens: 375
summary: "Script tools"
---

## Script tools

AI Agents can be equipped with script tools that extend their capabilities beyond text and image generation. Tools are Windmill [scripts](./meta-script_editor-index.md) that the AI can call to perform specific actions or retrieve information. You can add tools from three sources:

- **Inline scripts** - Write custom tools directly within the flow
- **Workspace scripts** - Use existing scripts from your Windmill workspace
- **Hub scripts** - Leverage pre-built tools from the Windmill Hub

Each script tool must have a unique name within the AI agent step and contain only letters, numbers, and underscores. It should be descriptive of the tool's function to help the AI understand when to use them.

When script tools are configured, the AI agent can decide when and how to use them based on the user's request. It selects the most appropriate tool by name, and issues a tool call with JSON arguments that conform to the tool's input schema. Windmill executes the underlying `script` and returns a JSON result, which is surfaced back to the model as a tool response message and is included in `messages`.

### MCP tools

AI Agents can connect to [MCP (Model Context Protocol)](./meta-51_mcp-index.md) servers as tools, enabling access to any tools exposed by MCP-compatible servers. To use MCP tools:

1. Create an MCP resource in Windmill with:
   - **Name**: Identifier for the MCP resource
   - **URL**: The MCP server endpoint URL
   - **Auth token** (optional): Authentication token for the MCP server
   - **Headers** (optional): Additional HTTP headers for the connection

2. Add the MCP resource to your AI Agent step as a tool

3. The AI agent will automatically discover and use tools exposed by the MCP server

**Note**: Only HTTP streamable MCP servers are supported.
