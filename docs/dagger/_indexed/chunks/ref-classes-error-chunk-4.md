---
doc_id: ref/classes/error
chunk_id: ref/classes/error#chunk-4
heading_path: ["error", "Methods"]
chunk_type: prose
tokens: 148
summary: "> **id**(): `Promise`<[`ErrorID`](/reference/typescript/api/client."
---
### id()

> **id**(): `Promise`<[`ErrorID`](/reference/typescript/api/client.gen/type-aliases/ErrorID)\>

A unique identifier for this Error.

#### Returns

`Promise`<[`ErrorID`](/reference/typescript/api/client.gen/type-aliases/ErrorID)\>

---

### message()

> **message**(): `Promise`<`string`\>

A description of the error.

#### Returns

`Promise`<`string`\>

---

### values()

> **values**(): `Promise`<[`ErrorValue`](/reference/typescript/api/client.gen/classes/ErrorValue)\[\]>

The extensions of the error.

#### Returns

`Promise`<[`ErrorValue`](/reference/typescript/api/client.gen/classes/ErrorValue)\[\]>

---

### with()

> **with**(`arg`): `Error`

Call the provided function with current Error.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `Error`

#### Returns

`Error`

---

### withValue()

> **withValue**(`name`, `value`): `Error`

Add a value to the error.

#### Parameters

#### name

`string`

The name of the value.

#### value

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

The value to store on the error.

#### Returns

`Error`
