---
doc_id: concept/extending/return-types
chunk_id: concept/extending/return-types#chunk-1
heading_path: ["return-types"]
chunk_type: prose
tokens: 160
summary: "> **Context**: In addition to returning basic types (string, boolean, ."
---
# Return Types

> **Context**: In addition to returning basic types (string, boolean, ...), Dagger Functions can also return any of Dagger's core types, such as `Directory`, `Contai...


In addition to returning basic types (string, boolean, ...), Dagger Functions can also return any of Dagger's core types, such as `Directory`, `Container`, `Service`, `Secret`, and many more.

This opens powerful applications to Dagger Functions. For example, a Dagger Function that builds binaries could take a directory with the source code as argument and return another directory (a "just-in-time" directory) containing just binaries or a container image (a "just-in-time" container) with the binaries included.

> **Note:** If a function doesn't have a return type annotation, it'll be translated to the [dagger.Void](https://docs.dagger.io/api/reference/#definition-Void) type in the API.
