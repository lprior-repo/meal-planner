---
id: ref/classes/enumvaluetypedef
title: "Class: EnumValueTypeDef"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: EnumValueTypeDef

> **Context**: A definition of a value in a custom enum defined in a Module.


A definition of a value in a custom enum defined in a Module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new EnumValueTypeDef**(`ctx?`, `_id?`, `_deprecated?`, `_description?`, `_name?`, `_value?`): `EnumValueTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`EnumValueTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumValueTypeDefID)

#### \_deprecated?

`string`

#### \_description?

`string`

#### \_name?

`string`

#### \_value?

`string`

#### Returns

`EnumValueTypeDef`

#### Overrides

`BaseClient.constructor`

## Methods

### deprecated()

> **deprecated**(): `Promise`<`string`\>

The reason this enum member is deprecated, if any.

#### Returns

`Promise`<`string`\>

---

### description()

> **description**(): `Promise`<`string`\>

A doc string for the enum member, if any.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`EnumValueTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumValueTypeDefID)\>

A unique identifier for this EnumValueTypeDef.

#### Returns

`Promise`<[`EnumValueTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumValueTypeDefID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the enum member.

#### Returns

`Promise`<`string`\>

---

### sourceMap()

> **sourceMap**(): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The location of this enum member declaration.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### value()

> **value**(): `Promise`<`string`\>

The value of the enum member

#### Returns

`Promise`<`string`\>

## See Also

- [Documentation Overview](./COMPASS.md)
