---
id: ref/classes/functionarg
title: "Class: FunctionArg"
category: ref
tags: ["ref", "ci", "directory", "typescript", "function"]
---

# Class: FunctionArg

> **Context**: An argument accepted by a function.


An argument accepted by a function.

This is a specification for an argument at function definition time, not an argument passed at function call time.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new FunctionArg**(`ctx?`, `_id?`, `_defaultPath?`, `_defaultValue?`, `_deprecated?`, `_description?`, `_name?`): `FunctionArg`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`FunctionArgID`](/reference/typescript/api/client.gen/type-aliases/FunctionArgID)

#### \_defaultPath?

`string`

#### \_defaultValue?

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

#### \_deprecated?

`string`

#### \_description?

`string`

#### \_name?

`string`

#### Returns

`FunctionArg`

#### Overrides

`BaseClient.constructor`

## Methods

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

## See Also

- [Documentation Overview](./COMPASS.md)
