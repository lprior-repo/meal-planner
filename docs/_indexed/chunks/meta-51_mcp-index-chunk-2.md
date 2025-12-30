---
doc_id: meta/51_mcp/index
chunk_id: meta/51_mcp/index#chunk-2
heading_path: ["Windmill MCP", "How to use"]
chunk_type: code
tokens: 349
summary: "How to use"
---

## How to use

### Generate your MCP token and URL

1. Navigate to your **account settings** in Windmill.
2. Create a new **token** under the **Tokens** section, and select **Generate MCP URL**.

![Generate MCP token](./user_settings.png 'Generate MCP token')

Once created, your MCP URL will look like this:

```yaml
https://app.windmill.dev/api/mcp/w/<your-workspace-id>/sse?token=<your-token>
```

> This token is used to authenticate MCP clients and generate your personal MCP endpoint URL. Save this URL securely. Treat it like an API key—anyone with access can trigger actions in your workspace.

---

### Connect your LLM to Windmill

Most modern LLM agents and interfaces now support MCP as a plug-and-play integration. The Windmill MCP server uses **HTTP streamable** as the transport layer, and MCP clients should be configured to use that protocol. Here are some examples configurations, for Claude Desktop and Cursor.

To connect with Cursor:

  - Go to Cursor > Settings > MCP Tools
  - Click on "Add a Custom MCP server"
  - Add the following configuration in the json file:

```json
{
  "mcpServers": {
    "windmill-mcp": {
      "url": "https://app.windmill.dev/api/mcp/w/<your-workspace-id>/sse?token=<your-token>"
    }
  }
}
```

To connect with Claude:

- Go to Claude > Settings > Integrations ([here](https://claude.ai/settings/integrations))
- Click on "Add an integration"
- Choose a name for your integration (e.g. "Windmill")
- Add your MCP URL in the "URL" field

To connect with Claude Code:

- Use the Claude Code CLI to add the Windmill MCP server:

```bash
claude mcp add --transport http windmill <windmill_url_with_token>
```

Replace `<windmill_url_with_token>` with your actual MCP URL from the previous step.

Once connected, your LLM will be able to run any script or flow in your Windmill workspace.
