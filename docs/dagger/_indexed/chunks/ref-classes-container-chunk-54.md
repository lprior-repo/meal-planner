---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-54
heading_path: ["container", "Methods", "withNewFile()"]
chunk_type: prose
tokens: 74
summary: "> **withNewFile**(`path`, `contents`, `opts?"
---
> **withNewFile**(`path`, `contents`, `opts?`): `Container`

Return a new container snapshot, with a file added to its filesystem with text content

#### Parameters

#### path

`string`

Path of the new file. May be relative or absolute. Example: "README.md" or "/etc/profile"

#### contents

`string`

Contents of the new file. Example: "Hello world!"

#### opts?

[`ContainerWithNewFileOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithNewFileOpts)

#### Returns

`Container`

---
