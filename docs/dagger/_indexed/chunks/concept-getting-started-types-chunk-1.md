---
doc_id: concept/getting-started/types
chunk_id: concept/getting-started/types#chunk-1
heading_path: ["types"]
chunk_type: table
tokens: 380
summary: "> **Context**: In addition to basic types (string, boolean, integer, arrays."
---
# Types

> **Context**: In addition to basic types (string, boolean, integer, arrays...), the Dagger API also provides powerful types which you can use as both arguments and...


In addition to basic types (string, boolean, integer, arrays...), the Dagger API also provides powerful types which you can use as both arguments and return values for Dagger Functions.

> **Note:** The types listed on this page are indicative and not exhaustive. For a complete list of supported types and their fields, refer to the [Dagger API reference](https://docs.dagger.io/api/reference).

The following table lists some of the available types and what they represent:

| Type | Description |
|------|-------------|
| [`CacheVolume`](/getting-started/types/cachevolume) | A directory whose contents persist across runs |
| [`Container`](/getting-started/types/container) | An OCI-compatible container |
| `CurrentModule` | The current Dagger module and its context |
| `Engine` | The Dagger Engine configuration and state |
| [`Directory`](/getting-started/types/directory) | A directory (local path or Git reference) |
| `EnvVariable` | An environment variable name and value |
| [`Env`](/getting-started/types/env) | An environment variable name and value |
| [`File`](/getting-started/types/file) | A file |
| [`GitRepository`](/getting-started/types/git) | A Git repository |
| `GitRef` | A Git reference (tag, branch, or commit) |
| `Host` | The Dagger host environment |
| [`LLM`](/getting-started/types/llm) | A Large Language Model (LLM) |
| `Module` | A Dagger module |
| `Port` | A port exposed by a container |
| [`Secret`](/getting-started/types/secret) | A secret credential like a password, access token or key |
| [`Service`](/getting-started/types/service) | A content-addressed service providing TCP connectivity |
| `Socket` | A Unix or TCP/IP socket that can be mounted into a container |
| `Terminal` | An interactive terminal session |

Each type exposes additional fields. Some of these are discussed below.
