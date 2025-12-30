---
doc_id: ref/classes/check
chunk_id: ref/classes/check#chunk-4
heading_path: ["check", "Methods"]
chunk_type: prose
tokens: 199
summary: "> **completed**(): `Promise`<`boolean`\>

Whether the check completed



`Promise`<`boolean`\>

-..."
---
### completed()

> **completed**(): `Promise`<`boolean`\>

Whether the check completed

#### Returns

`Promise`<`boolean`\>

---

### description()

> **description**(): `Promise`<`string`\>

The description of the check

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`CheckID`](/reference/typescript/api/client.gen/type-aliases/CheckID)\>

A unique identifier for this Check.

#### Returns

`Promise`<[`CheckID`](/reference/typescript/api/client.gen/type-aliases/CheckID)\>

---

### name()

> **name**(): `Promise`<`string`\>

Return the fully qualified name of the check

#### Returns

`Promise`<`string`\>

---

### passed()

> **passed**(): `Promise`<`boolean`\>

Whether the check passed

#### Returns

`Promise`<`boolean`\>

---

### path()

> **path**(): `Promise`<`string`\[\]>

The path of the check within its module

#### Returns

`Promise`<`string`\[\]>

---

### resultEmoji()

> **resultEmoji**(): `Promise`<`string`\>

An emoji representing the result of the check

#### Returns

`Promise`<`string`\>

---

### run()

> **run**(): `Check`

Execute the check

#### Returns

`Check`

---

### with()

> **with**(`arg`): `Check`

Call the provided function with current Check.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `Check`

#### Returns

`Check`
