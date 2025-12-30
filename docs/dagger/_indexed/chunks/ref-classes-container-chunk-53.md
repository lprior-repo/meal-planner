---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-53
heading_path: ["container", "Methods", "withMountedTemp()"]
chunk_type: prose
tokens: 69
summary: "> **withMountedTemp**(`path`, `opts?"
---
> **withMountedTemp**(`path`, `opts?`): `Container`

Retrieves this container plus a temporary directory mounted at the given path. Any writes will be ephemeral to a single withExec call; they will not be persisted to subsequent withExecs.

#### Parameters

#### path

`string`

Location of the temporary directory (e.g., "/tmp/temp\_dir").

#### opts?

[`ContainerWithMountedTempOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedTempOpts)

#### Returns

`Container`

---
