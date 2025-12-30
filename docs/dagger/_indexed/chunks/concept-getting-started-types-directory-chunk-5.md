---
doc_id: concept/getting-started/types-directory
chunk_id: concept/getting-started/types-directory#chunk-5
heading_path: ["types-directory", "Mounts"]
chunk_type: prose
tokens: 121
summary: "When working with directories and files, you can choose whether to copy or mount them:

- `Contai..."
---
When working with directories and files, you can choose whether to copy or mount them:

- `Container.withDirectory()` - returns a container plus a directory written at the given path
- `Container.withFile()` - returns a container plus a file written at the given path
- `Container.withMountedDirectory()` - returns a container plus a directory mounted at the given path
- `Container.withMountedFile()` - returns a container plus a file mounted at the given path

Mounts only take effect within your workflow invocation; they are not copied to the final image. Mounts are more performant and resource-efficient.
