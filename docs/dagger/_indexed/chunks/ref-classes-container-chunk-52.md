---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-52
heading_path: ["container", "Methods", "withMountedSecret()"]
chunk_type: prose
tokens: 61
summary: "> **withMountedSecret**(`path`, `source`, `opts?"
---
> **withMountedSecret**(`path`, `source`, `opts?`): `Container`

Retrieves this container plus a secret mounted into a file at the given path.

#### Parameters

#### path

`string`

Location of the secret file (e.g., "/tmp/secret.txt").

#### source

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Identifier of the secret to mount.

#### opts?

[`ContainerWithMountedSecretOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedSecretOpts)

#### Returns

`Container`

---
