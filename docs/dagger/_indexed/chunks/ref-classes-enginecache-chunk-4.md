---
doc_id: ref/classes/enginecache
chunk_id: ref/classes/enginecache#chunk-4
heading_path: ["enginecache", "Methods"]
chunk_type: prose
tokens: 178
summary: "> **entrySet**(`opts?"
---
### entrySet()

> **entrySet**(`opts?`): [`EngineCacheEntrySet`](/reference/typescript/api/client.gen/classes/EngineCacheEntrySet)

The current set of entries in the cache

#### Parameters

#### opts?

[`EngineCacheEntrySetOpts`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetOpts)

#### Returns

[`EngineCacheEntrySet`](/reference/typescript/api/client.gen/classes/EngineCacheEntrySet)

---

### id()

> **id**(): `Promise`<[`EngineCacheID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheID)\>

A unique identifier for this EngineCache.

#### Returns

`Promise`<[`EngineCacheID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheID)\>

---

### maxUsedSpace()

> **maxUsedSpace**(): `Promise`<`number`\>

The maximum bytes to keep in the cache without pruning.

#### Returns

`Promise`<`number`\>

---

### minFreeSpace()

> **minFreeSpace**(): `Promise`<`number`\>

The target amount of free disk space the garbage collector will attempt to leave.

#### Returns

`Promise`<`number`\>

---

### prune()

> **prune**(`opts?`): `Promise`<`void`\>

Prune the cache of releaseable entries

#### Parameters

#### opts?

[`EngineCachePruneOpts`](/reference/typescript/api/client.gen/type-aliases/EngineCachePruneOpts)

#### Returns

`Promise`<`void`\>

---

### reservedSpace()

> **reservedSpace**(): `Promise`<`number`\>

The minimum amount of disk space this policy is guaranteed to retain.

#### Returns

`Promise`<`number`\>

---

### targetSpace()

> **targetSpace**(): `Promise`<`number`\>

The target number of bytes to keep when pruning.

#### Returns

`Promise`<`number`\>
