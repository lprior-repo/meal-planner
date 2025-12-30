---
doc_id: ops/cookbook/errors
chunk_id: ops/cookbook/errors#chunk-3
heading_path: ["errors", "Continue using a container after command execution fails"]
chunk_type: prose
tokens: 87
summary: "The following Dagger Function demonstrates how to continue using a container after a command exec..."
---
The following Dagger Function demonstrates how to continue using a container after a command executed within it fails. A common use case for this is to export a report that a test suite tool generates.

> **Note**: The caveat with this approach is that forcing a zero exit code on a failure caches the failure. This may not be desired depending on the use case.

### Go
