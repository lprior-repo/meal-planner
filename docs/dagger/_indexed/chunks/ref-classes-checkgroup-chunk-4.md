---
doc_id: ref/classes/checkgroup
chunk_id: ref/classes/checkgroup#chunk-4
heading_path: ["checkgroup", "Methods"]
chunk_type: prose
tokens: 122
summary: "> **id**(): `Promise`<[`CheckGroupID`](/reference/typescript/api/client."
---
### id()

> **id**(): `Promise`<[`CheckGroupID`](/reference/typescript/api/client.gen/type-aliases/CheckGroupID)\>

A unique identifier for this CheckGroup.

#### Returns

`Promise`<[`CheckGroupID`](/reference/typescript/api/client.gen/type-aliases/CheckGroupID)\>

---

### list()

> **list**(): `Promise`<[`Check`](/reference/typescript/api/client.gen/classes/Check)\[\]>

Return a list of individual checks and their details

#### Returns

`Promise`<[`Check`](/reference/typescript/api/client.gen/classes/Check)\[\]>

---

### report()

> **report**(): [`File`](/reference/typescript/api/client.gen/classes/File)

Generate a markdown report

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### run()

> **run**(): `CheckGroup`

Execute all selected checks

#### Returns

`CheckGroup`

---

### with()

> **with**(`arg`): `CheckGroup`

Call the provided function with current CheckGroup.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `CheckGroup`

#### Returns

`CheckGroup`
