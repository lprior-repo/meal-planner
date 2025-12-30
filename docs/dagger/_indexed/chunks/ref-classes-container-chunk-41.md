---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-41
heading_path: ["container", "Methods", "withEntrypoint()"]
chunk_type: prose
tokens: 56
summary: "> **withEntrypoint**(`args`, `opts?"
---
> **withEntrypoint**(`args`, `opts?`): `Container`

Set an OCI-style entrypoint. It will be included in the container's OCI configuration. Note, withExec ignores the entrypoint by default.

#### Parameters

#### args

`string`\[\]

Arguments of the entrypoint. Example: \["go", "run"\].

#### opts?

[`ContainerWithEntrypointOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithEntrypointOpts)

#### Returns

`Container`

---
