---
doc_id: concept/getting-started/api-sdk
chunk_id: concept/getting-started/api-sdk#chunk-1
heading_path: ["api-sdk"]
chunk_type: prose
tokens: 252
summary: "> **Context**: Dagger SDKs make it easy to call the Dagger API from your favorite programming lan..."
---
# Using Dagger SDKs

> **Context**: Dagger SDKs make it easy to call the Dagger API from your favorite programming language, by developing Dagger Functions or custom applications.


Dagger SDKs make it easy to call the Dagger API from your favorite programming language, by developing Dagger Functions or custom applications.

A Dagger SDK provides two components:

- A client library to call the Dagger API from your code
- Tooling to extend the Dagger API with your own Dagger Functions (bundled in a Dagger module)

The Dagger API uses GraphQL as its low-level language-agnostic framework, and can also be accessed using any standard GraphQL client. However, you do not need to know GraphQL to call the Dagger API; the translation to underlying GraphQL API calls is handled internally by the Dagger SDKs.

Official Dagger SDKs are currently available for Go, TypeScript and Python. There are also [experimental and community SDKs contributed by the Dagger community](https://github.com/dagger/dagger/tree/main/sdk).

> **Custom applications:** Dagger SDKs can also be used to build custom applications that use the Dagger API. These applications can be standalone or integrated into existing systems, allowing you to leverage Dagger's capabilities in your own software solutions.
