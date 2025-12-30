---
doc_id: ref/classes/enginecacheentryset
chunk_id: ref/classes/enginecacheentryset#chunk-4
heading_path: ["enginecacheentryset", "Methods"]
chunk_type: prose
tokens: 91
summary: "> **diskSpaceBytes**(): `Promise`<`number`\>

The total disk space used by the cache entries in t..."
---
### diskSpaceBytes()

> **diskSpaceBytes**(): `Promise`<`number`\>

The total disk space used by the cache entries in this set.

#### Returns

`Promise`<`number`\>

---

### entries()

> **entries**(): `Promise`<[`EngineCacheEntry`](/reference/typescript/api/client.gen/classes/EngineCacheEntry)\[\]>

The list of individual cache entries in the set

#### Returns

`Promise`<[`EngineCacheEntry`](/reference/typescript/api/client.gen/classes/EngineCacheEntry)\[\]>

---

### entryCount()

> **entryCount**(): `Promise`<`number`\>

The number of cache entries in this set.

#### Returns

`Promise`<`number`\>

---

### id()

> **id**(): `Promise`<[`EngineCacheEntrySetID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetID)\>

A unique identifier for this EngineCacheEntrySet.

#### Returns

`Promise`<[`EngineCacheEntrySetID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetID)\>
