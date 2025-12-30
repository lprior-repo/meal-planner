---
doc_id: ref/classes/enginecacheentry
chunk_id: ref/classes/enginecacheentry#chunk-4
heading_path: ["enginecacheentry", "Methods"]
chunk_type: prose
tokens: 134
summary: "> **activelyUsed**(): `Promise`<`boolean`\>

Whether the cache entry is actively being used."
---
### activelyUsed()

> **activelyUsed**(): `Promise`<`boolean`\>

Whether the cache entry is actively being used.

#### Returns

`Promise`<`boolean`\>

---

### createdTimeUnixNano()

> **createdTimeUnixNano**(): `Promise`<`number`\>

The time the cache entry was created, in Unix nanoseconds.

#### Returns

`Promise`<`number`\>

---

### description()

> **description**(): `Promise`<`string`\>

The description of the cache entry.

#### Returns

`Promise`<`string`\>

---

### diskSpaceBytes()

> **diskSpaceBytes**(): `Promise`<`number`\>

The disk space used by the cache entry.

#### Returns

`Promise`<`number`\>

---

### id()

> **id**(): `Promise`<[`EngineCacheEntryID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntryID)\>

A unique identifier for this EngineCacheEntry.

#### Returns

`Promise`<[`EngineCacheEntryID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntryID)\>

---

### mostRecentUseTimeUnixNano()

> **mostRecentUseTimeUnixNano**(): `Promise`<`number`\>

The most recent time the cache entry was used, in Unix nanoseconds.

#### Returns

`Promise`<`number`\>
