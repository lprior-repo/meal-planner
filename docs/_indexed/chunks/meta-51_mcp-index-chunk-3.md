---
doc_id: meta/51_mcp/index
chunk_id: meta/51_mcp/index#chunk-3
heading_path: ["Windmill MCP", "Example: Triggering a script from Claude"]
chunk_type: prose
tokens: 101
summary: "Example: Triggering a script from Claude"
---

## Example: Triggering a script from Claude

Say you’ve created a script called `send_welcome_email`.

Once your MCP server is connected, in Claude you could type:

> “Send an email to user@example.com with the subject 'Welcome' and the body 'Welcome to our service!' with Windmill”
<br/>

Claude will:

- Find the `send_welcome_email` script in your windmill workspace
- Ask you for required inputs if needed
- Run the script and show you the result right inside the chat

---
