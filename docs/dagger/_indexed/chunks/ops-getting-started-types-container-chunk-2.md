---
doc_id: ops/getting-started/types-container
chunk_id: ops/getting-started/types-container#chunk-2
heading_path: ["types-container", "Common operations"]
chunk_type: table
tokens: 287
summary: "| Field | Description |
|-------|-------------|
| `from` | Initializes the container from a specifie"
---
| Field | Description |
|-------|-------------|
| `from` | Initializes the container from a specified base image |
| `asService` | Turns the container into a `Service` |
| `asTarball` | Returns a serialized tarball of the container as a `File` |
| `export` / `import` | Writes / reads the container as an OCI tarball to / from a file path on the host |
| `publish` | Publishes the container image to a registry |
| `stdout` / `stderr` | Returns the output / error stream of the last executed command |
| `withDirectory` / `withMountedDirectory` | Returns the container plus a directory copied / mounted at the given path |
| `withEntrypoint` | Returns the container with a custom entrypoint command |
| `withExec` | Returns the container after executing a command inside it |
| `withFile` / `withMountedFile` | Returns the container plus a file copied / mounted at the given path |
| `withMountedCache` | Returns the container plus a cache volume mounted at the given path |
| `withRegistryAuth` | Returns the container with registry authentication configured |
| `withWorkdir` | Returns the container configured with a specific working directory |
| `withServiceBinding` | Returns the container with runtime dependency on another `Service` |
| `terminal` | Opens an interactive terminal for this container |
