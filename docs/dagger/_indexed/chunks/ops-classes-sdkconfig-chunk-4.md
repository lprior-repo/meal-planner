---
doc_id: ops/classes/sdkconfig
chunk_id: ops/classes/sdkconfig#chunk-4
heading_path: ["sdkconfig", "Methods"]
chunk_type: prose
tokens: 87
summary: "> **debug**(): `Promise`<`boolean`\>

Whether to start the SDK runtime in debug mode with an inte..."
---
### debug()

> **debug**(): `Promise`<`boolean`\>

Whether to start the SDK runtime in debug mode with an interactive terminal.

#### Returns

`Promise`<`boolean`\>

---

### id()

> **id**(): `Promise`<[`SDKConfigID`](/reference/typescript/api/client.gen/type-aliases/SDKConfigID)\>

A unique identifier for this SDKConfig.

#### Returns

`Promise`<[`SDKConfigID`](/reference/typescript/api/client.gen/type-aliases/SDKConfigID)\>

---

### source()

> **source**(): `Promise`<`string`\>

Source of the SDK. Either a name of a builtin SDK or a module source ref string pointing to the SDK's implementation.

#### Returns

`Promise`<`string`\>
