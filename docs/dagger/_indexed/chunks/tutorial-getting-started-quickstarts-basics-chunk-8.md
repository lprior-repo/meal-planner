---
doc_id: tutorial/getting-started/quickstarts-basics
chunk_id: tutorial/getting-started/quickstarts-basics#chunk-8
heading_path: ["quickstarts-basics", "Use arguments and return values"]
chunk_type: prose
tokens: 79
summary: "Dagger Functions accept arguments and return values."
---
Dagger Functions accept arguments and return values. In addition to common types (string, boolean, integer, arrays...), the Dagger API also defines powerful types like `Directory`, `Container`, `Service`, `Secret`.

### Sandboxing

Dagger Functions are fully "sandboxed" and do not have direct access to the host system. Host resources such as directories, files, environment variables, network services must be explicitly passed as arguments.
