---
doc_id: ref/classes/functioncall
chunk_id: ref/classes/functioncall#chunk-4
heading_path: ["functioncall", "Methods"]
chunk_type: prose
tokens: 225
summary: "> **id**(): `Promise`<[`FunctionCallID`](/reference/typescript/api/client."
---
### id()

> **id**(): `Promise`<[`FunctionCallID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallID)\>

A unique identifier for this FunctionCall.

#### Returns

`Promise`<[`FunctionCallID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallID)\>

---

### inputArgs()

> **inputArgs**(): `Promise`<[`FunctionCallArgValue`](/reference/typescript/api/client.gen/classes/FunctionCallArgValue)\[\]>

The argument values the function is being invoked with.

#### Returns

`Promise`<[`FunctionCallArgValue`](/reference/typescript/api/client.gen/classes/FunctionCallArgValue)\[\]>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the function being called.

#### Returns

`Promise`<`string`\>

---

### parent()

> **parent**(): `Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

The value of the parent object of the function being called. If the function is top-level to the module, this is always an empty object.

#### Returns

`Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

---

### parentName()

> **parentName**(): `Promise`<`string`\>

The name of the parent object of the function being called. If the function is top-level to the module, this is the name of the module.

#### Returns

`Promise`<`string`\>

---

### returnError()

> **returnError**(`error`): `Promise`<`void`\>

Return an error from the function.

#### Parameters

#### error

[`Error`](/reference/typescript/api/client.gen/classes/Error)

The error to return.

#### Returns

`Promise`<`void`\>

---

### returnValue()

> **returnValue**(`value`): `Promise`<`void`\>

Set the return value of the function call to the provided value.

#### Parameters

#### value

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

JSON serialization of the return value.

#### Returns

`Promise`<`void`\>
