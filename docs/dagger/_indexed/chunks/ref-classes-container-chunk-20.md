---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-20
heading_path: ["container", "Methods", "from()"]
chunk_type: prose
tokens: 55
summary: "> **from**(`address`): `Container`

Download a container image, and apply it to the container state."
---
> **from**(`address`): `Container`

Download a container image, and apply it to the container state. All previous state will be lost.

#### Parameters

#### address

`string`

Address of the container image to download, in standard OCI ref format. Example:"registry.dagger.io/engine:latest"

#### Returns

`Container`

---
