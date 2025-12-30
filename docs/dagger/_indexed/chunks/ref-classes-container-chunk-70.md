---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-70
heading_path: ["container", "Methods", "withRegistryAuth()"]
chunk_type: prose
tokens: 83
summary: "> **withRegistryAuth**(`address`, `username`, `secret`): `Container`

Attach credentials for futu..."
---
> **withRegistryAuth**(`address`, `username`, `secret`): `Container`

Attach credentials for future publishing to a registry. Use in combination with publish

#### Parameters

#### address

`string`

The image address that needs authentication. Same format as "docker push". Example: "registry.dagger.io/dagger:latest"

#### username

`string`

The username to authenticate with. Example: "alice"

#### secret

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

The API key, password or token to authenticate to this registry

#### Returns

`Container`

---
