---
doc_id: ref/classes/functionarg
chunk_id: ref/classes/functionarg#chunk-4
heading_path: ["functionarg", "Methods"]
chunk_type: prose
tokens: 246
summary: "> **defaultPath**(): `Promise`<`string`\>

Only applies to arguments of type File or Directory."
---
### defaultPath()

> **defaultPath**(): `Promise`<`string`\>

Only applies to arguments of type File or Directory. If the argument is not set, load it from the given path in the context directory

#### Returns

`Promise`<`string`\>

---

### defaultValue()

> **defaultValue**(): `Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

A default value to use for this argument when not explicitly set by the caller, if any.

#### Returns

`Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

---

### deprecated()

> **deprecated**(): `Promise`<`string`\>

The reason this function is deprecated, if any.

#### Returns

`Promise`<`string`\>

---

### description()

> **description**(): `Promise`<`string`\>

A doc string for the argument, if any.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`FunctionArgID`](/reference/typescript/api/client.gen/type-aliases/FunctionArgID)\>

A unique identifier for this FunctionArg.

#### Returns

`Promise`<[`FunctionArgID`](/reference/typescript/api/client.gen/type-aliases/FunctionArgID)\>

---

### ignore()

> **ignore**(): `Promise`<`string`\[\]>

Only applies to arguments of type Directory. The ignore patterns are applied to the input directory, and matching entries are filtered out, in a cache-efficient manner.

#### Returns

`Promise`<`string`\[\]>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the argument in lowerCamelCase format.

#### Returns

`Promise`<`string`\>

---

### sourceMap()

> **sourceMap**(): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The location of this arg declaration.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### typeDef()

> **typeDef**(): [`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

The type of the argument.

#### Returns

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)
