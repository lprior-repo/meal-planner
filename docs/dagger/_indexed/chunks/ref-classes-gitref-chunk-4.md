---
doc_id: ref/classes/gitref
chunk_id: ref/classes/gitref#chunk-4
heading_path: ["gitref", "Methods"]
chunk_type: prose
tokens: 173
summary: "> **commit**(): `Promise`<`string`\>

The resolved commit id at this ref."
---
### commit()

> **commit**(): `Promise`<`string`\>

The resolved commit id at this ref.

#### Returns

`Promise`<`string`\>

---

### commonAncestor()

> **commonAncestor**(`other`): `GitRef`

Find the best common ancestor between this ref and another ref.

#### Parameters

#### other

`GitRef`

The other ref to compare against.

#### Returns

`GitRef`

---

### id()

> **id**(): `Promise`<[`GitRefID`](/reference/typescript/api/client.gen/type-aliases/GitRefID)\>

A unique identifier for this GitRef.

#### Returns

`Promise`<[`GitRefID`](/reference/typescript/api/client.gen/type-aliases/GitRefID)\>

---

### ref()

> **ref**(): `Promise`<`string`\>

The resolved ref name at this ref.

#### Returns

`Promise`<`string`\>

---

### tree()

> **tree**(`opts?`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The filesystem tree at this ref.

#### Parameters

#### opts?

[`GitRefTreeOpts`](/reference/typescript/api/client.gen/type-aliases/GitRefTreeOpts)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### with()

> **with**(`arg`): `GitRef`

Call the provided function with current GitRef.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `GitRef`

#### Returns

`GitRef`
