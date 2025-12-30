---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-75
heading_path: ["container", "Methods", "withUnixSocket()"]
chunk_type: prose
tokens: 61
summary: "> **withUnixSocket**(`path`, `source`, `opts?"
---
> **withUnixSocket**(`path`, `source`, `opts?`): `Container`

Retrieves this container plus a socket forwarded to the given Unix socket path.

#### Parameters

#### path

`string`

Location of the forwarded Unix socket (e.g., "/tmp/socket").

#### source

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Identifier of the socket to forward.

#### opts?

[`ContainerWithUnixSocketOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithUnixSocketOpts)

#### Returns

`Container`

---
