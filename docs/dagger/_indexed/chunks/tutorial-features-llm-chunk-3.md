---
doc_id: tutorial/features/llm
chunk_id: tutorial/features/llm#chunk-3
heading_path: ["llm", "MCP"]
chunk_type: prose
tokens: 151
summary: "Model Context Protocol (MCP) support in Dagger can be broken into two categories:

1."
---
Model Context Protocol (MCP) support in Dagger can be broken into two categories:

1. Exposing MCP outside Dagger
2. Connecting to external MCP servers from Dagger

### Expose MCP outside Dagger

Dagger has built-in MCP support that allows you to easily expose Dagger modules as an MCP server. This allows you to configure a client (such as Claude Desktop, Cursor, Goose CLI/Desktop) to consume modules from [the Daggerverse](https://daggerverse.dev) or any Git repository as native MCP servers.

> **Warning:** Currently, only Dagger modules with no required constructor arguments are supported when exposing an MCP server outside Dagger.

### Connect to external MCP servers from Dagger

Support for connecting to external MCP servers from Dagger is coming soon.
