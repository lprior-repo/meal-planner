---
doc_id: ref/classes/enumtypedef
chunk_id: ref/classes/enumtypedef#chunk-4
heading_path: ["enumtypedef", "Methods"]
chunk_type: prose
tokens: 146
summary: "> **description**(): `Promise`<`string`\>

A doc string for the enum, if any."
---
### description()

> **description**(): `Promise`<`string`\>

A doc string for the enum, if any.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`EnumTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumTypeDefID)\>

A unique identifier for this EnumTypeDef.

#### Returns

`Promise`<[`EnumTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumTypeDefID)\>

---

### members()

> **members**(): `Promise`<[`EnumValueTypeDef`](/reference/typescript/api/client.gen/classes/EnumValueTypeDef)\[\]>

The members of the enum.

#### Returns

`Promise`<[`EnumValueTypeDef`](/reference/typescript/api/client.gen/classes/EnumValueTypeDef)\[\]>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the enum.

#### Returns

`Promise`<`string`\>

---

### sourceMap()

> **sourceMap**(): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The location of this enum declaration.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### sourceModuleName()

> **sourceModuleName**(): `Promise`<`string`\>

If this EnumTypeDef is associated with a Module, the name of the module. Unset otherwise.

#### Returns

`Promise`<`string`\>

---

### values()

> **values**(): `Promise`<[`EnumValueTypeDef`](/reference/typescript/api/client.gen/classes/EnumValueTypeDef)\[\]>

#### Returns

`Promise`<[`EnumValueTypeDef`](/reference/typescript/api/client.gen/classes/EnumValueTypeDef)\[\]>

#### Deprecated

use members instead
