---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-16
heading_path: ["container", "Methods", "export()"]
chunk_type: prose
tokens: 68
summary: "> **export**(`path`, `opts?"
---
> **export**(`path`, `opts?`): `Promise`<`string`\>

Writes the container as an OCI tarball to the destination file path on the host.

It can also export platform variants.

#### Parameters

#### path

`string`

Host's destination path (e.g., "./tarball").

Path can be relative to the engine's workdir or absolute.

#### opts?

[`ContainerExportOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerExportOpts)

#### Returns

`Promise`<`string`\>

---
