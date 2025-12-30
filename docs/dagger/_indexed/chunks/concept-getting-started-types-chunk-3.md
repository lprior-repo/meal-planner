---
doc_id: concept/getting-started/types
chunk_id: concept/getting-started/types#chunk-3
heading_path: ["types", "CurrentModule"]
chunk_type: table
tokens: 126
summary: "The `CurrentModule` type provides capabilities to introspect the Dagger Function's module and int..."
---
The `CurrentModule` type provides capabilities to introspect the Dagger Function's module and interface between the current execution environment and the Dagger API.

### Common operations

| Field | Description |
|-------|-------------|
| `source` | Returns the directory containing the module's source code |
| `workdir` | Loads and returns a directory from the module's working directory, including any changes that may have been made to it during function execution |
| `workdirFile` | Loads and returns a file from the module's working directory, including any changes that may have been made to it during function execution |
