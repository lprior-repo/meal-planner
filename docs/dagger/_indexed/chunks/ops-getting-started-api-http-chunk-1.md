---
doc_id: ops/getting-started/api-http
chunk_id: ops/getting-started/api-http#chunk-1
heading_path: ["api-http"]
chunk_type: prose
tokens: 295
summary: "> **Context**: The Dagger API is an HTTP API that uses GraphQL as its low-level language-agnostic..."
---
# Using the Dagger API with HTTP and GraphQL

> **Context**: The Dagger API is an HTTP API that uses GraphQL as its low-level language-agnostic framework. Therefore, it's possible to call the Dagger API using ra...


The Dagger API is an HTTP API that uses GraphQL as its low-level language-agnostic framework. Therefore, it's possible to call the Dagger API using raw HTTP queries, from [any language that supports GraphQL](https://graphql.org/code/). GraphQL has a large and growing list of client implementations in over 20 languages.

> **Note:** In practice, calling the API using HTTP or GraphQL is optional. Typically, you will instead use a custom Dagger function created with a type-safe Dagger SDK, or from the command line using the Dagger CLI.

Dagger creates a unique local API endpoint for GraphQL HTTP queries for every Dagger session. This API endpoint is served by the local host at the port specified by the `DAGGER_SESSION_PORT` environment variable, and can be directly read from the environment in your client code. For example, if `DAGGER_SESSION_PORT` is set to `12345`, the API endpoint can be reached at `http://127.0.0.1:$DAGGER_SESSION_PORT/query`

> **Warning:** Dagger protects the exposed API with an HTTP Basic authentication token which can be retrieved from the `DAGGER_SESSION_TOKEN` variable. Treat the `DAGGER_SESSION_TOKEN` value as you would any other sensitive credential. Store it securely and avoid passing it to, or over, insecure applications and networks.
