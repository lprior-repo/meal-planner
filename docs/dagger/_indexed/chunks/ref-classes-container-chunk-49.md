---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-49
heading_path: ["container", "Methods", "withMountedCache()"]
chunk_type: prose
tokens: 60
summary: "> **withMountedCache**(`path`, `cache`, `opts?"
---
> **withMountedCache**(`path`, `cache`, `opts?`): `Container`

Retrieves this container plus a cache volume mounted at the given path.

#### Parameters

#### path

`string`

Location of the cache directory (e.g., "/root/.npm").

#### cache

[`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

Identifier of the cache volume to mount.

#### opts?

[`ContainerWithMountedCacheOpts`](/reference/typescript/api/client.gen/type-aliases/ContainerWithMountedCacheOpts)

#### Returns

`Container`

---
