---
doc_id: ops/getting-started/api-http
chunk_id: ops/getting-started/api-http#chunk-4
heading_path: ["api-http", "Dagger CLI"]
chunk_type: mixed
tokens: 77
summary: "The Dagger CLI offers a `dagger query` sub-command, which provides an easy way to send raw GraphQ..."
---
The Dagger CLI offers a `dagger query` sub-command, which provides an easy way to send raw GraphQL queries to the Dagger API from the command line.

This example demonstrates how to build a Go application by cloning the canonical Git repository for Go and building the "Hello, world" example program:

Create a new shell script named `build.sh`:

```bash
#!/bin/bash
