---
doc_id: ref/classes/engine
chunk_id: ref/classes/engine#chunk-4
heading_path: ["engine", "Methods"]
chunk_type: prose
tokens: 79
summary: "> **clients**(): `Promise`<`string`\[\]>

The list of connected client IDs



`Promise`<`string`\..."
---
### clients()

> **clients**(): `Promise`<`string`\[\]>

The list of connected client IDs

#### Returns

`Promise`<`string`\[\]>

---

### id()

> **id**(): `Promise`<[`EngineID`](/reference/typescript/api/client.gen/type-aliases/EngineID)\>

A unique identifier for this Engine.

#### Returns

`Promise`<[`EngineID`](/reference/typescript/api/client.gen/type-aliases/EngineID)\>

---

### localCache()

> **localCache**(): [`EngineCache`](/reference/typescript/api/client.gen/classes/EngineCache)

The local (on-disk) cache for the Dagger engine

#### Returns

[`EngineCache`](/reference/typescript/api/client.gen/classes/EngineCache)

---

### name()

> **name**(): `Promise`<`string`\>

The name of the engine instance.

#### Returns

`Promise`<`string`\>
