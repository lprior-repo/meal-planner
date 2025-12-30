---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-28
heading_path: ["container", "Methods", "publish()"]
chunk_type: prose
tokens: 70
summary: "> **publish**(`address`, `opts?"
---
> **publish**(`address`, `opts?`): `Promise`<`string`\>

Package the container state as an OCI image, and publish it to a registry

Returns the fully qualified address of the published image, with digest

#### Parameters

#### address

`string`

The OCI address to publish to

Same format as "docker push". Example: "registry.example.com/user/repo:tag"

#### opts?

[`ContainerPublishOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerPublishOpts)

#### Returns

`Promise`<`string`\>

---
