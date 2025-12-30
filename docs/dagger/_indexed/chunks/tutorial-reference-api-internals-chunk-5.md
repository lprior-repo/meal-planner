---
doc_id: tutorial/reference/api-internals
chunk_id: tutorial/reference/api-internals#chunk-5
heading_path: ["api-internals", "Dynamic API Extension"]
chunk_type: prose
tokens: 103
summary: "1."
---
1. When you execute a Dagger CLI command, it connects to an existing engine or provisions one on-the-fly.

2. Each session is associated with its own GraphQL server instance. The core API provides basic functionality like running containers, interacting with files and directories.

3. When a module is loaded into the session, the GraphQL API is dynamically extended with new APIs served by that module.

4. Dagger modules are themselves also Dagger clients connected back to the same session.
