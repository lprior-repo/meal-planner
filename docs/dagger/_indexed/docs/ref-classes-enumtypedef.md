---
id: ref/classes/enumtypedef
title: "Class: EnumTypeDef"
category: ref
tags: ["ref", "api", "typescript", "module", "cli"]
---

# Class: EnumTypeDef

> **Context**: A definition of a custom enum defined in a Module.


A definition of a custom enum defined in a Module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new EnumTypeDef**(`ctx?`, `_id?`, `_description?`, `_name?`, `_sourceModuleName?`): `EnumTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`EnumTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumTypeDefID)

#### \_description?

`string`

#### \_name?

`string`

#### \_sourceModuleName?

`string`

#### Returns

`EnumTypeDef`

#### Overrides

`BaseClient.constructor`

## Methods

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

## See Also

- [Documentation Overview](./COMPASS.md)
