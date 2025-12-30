---
doc_id: ops/getting-started/types-container
chunk_id: ops/getting-started/types-container#chunk-1
heading_path: ["types-container"]
chunk_type: prose
tokens: 104
summary: "> **Context**: The `Container` type represents the state of an OCI-compatible container."
---
# Container

> **Context**: The `Container` type represents the state of an OCI-compatible container. This `Container` object is not merely a string referencing an image on a rem...


The `Container` type represents the state of an OCI-compatible container. This `Container` object is not merely a string referencing an image on a remote registry. It is the actual state of a container, managed by the Dagger Engine, and passed to a Dagger Function's code as if it were just another variable.
