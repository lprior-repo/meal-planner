---
doc_id: concept/getting-started/concepts
chunk_id: concept/getting-started/concepts#chunk-6
heading_path: ["concepts", "Calling the Dagger API"]
chunk_type: prose
tokens: 169
summary: "You can call the Dagger API from code using a type-safe Dagger SDK, or from the command line usin..."
---
You can call the Dagger API from code using a type-safe Dagger SDK, or from the command line using the Dagger CLI or the Dagger Shell.

The different ways to call the Dagger API are:

- From the Dagger CLI
  - [`dagger`, `dagger core` and `dagger call`](/getting-started/api/cli)
- From a custom application created with a Dagger SDK
  - [`dagger run`](/extending/custom-applications/go)
- From a [language-native GraphQL client](/getting-started/api/http#language-native-http-clients)
- From a command-line HTTP or GraphQL client
  - [`curl`](/getting-started/api/http#command-line-http-clients)
  - [`dagger query`](/getting-started/api/http#dagger-cli)

> **Note:** The Dagger CLI can call any Dagger function, either from your local filesystem or from a remote Git repository. They can be used interactively, from a shell script, or from a CI configuration. Apart from the Dagger CLI, no other infrastructure or tooling is required to call Dagger functions.
