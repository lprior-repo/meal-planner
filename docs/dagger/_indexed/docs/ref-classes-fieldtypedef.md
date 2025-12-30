---
id: ref/classes/fieldtypedef
title: "Class: FieldTypeDef"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: FieldTypeDef

> **Context**: A definition of a field on a custom object defined in a Module.


A definition of a field on a custom object defined in a Module.

A field on an object has a static value, as opposed to a function on an object whose value is computed by invoking code (and can accept arguments).

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new FieldTypeDef**(`ctx?`, `_id?`, `_deprecated?`, `_description?`, `_name?`): `FieldTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`FieldTypeDefID`](/reference/typescript/api/client.gen/type-aliases/FieldTypeDefID)

#### \_deprecated?

`string`

#### \_description?

`string`

#### \_name?

`string`

#### Returns

`FieldTypeDef`

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

A doc string for the field, if any.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`FieldTypeDefID`](/reference/typescript/api/client.gen/type-aliases/FieldTypeDefID)\>

A unique identifier for this FieldTypeDef.

#### Returns

`Promise`<[`FieldTypeDefID`](/reference/typescript/api/client.gen/type-aliases/FieldTypeDefID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the field in lowerCamelCase format.

#### Returns

`Promise`<`string`\>

---

### sourceMap()

> **sourceMap**(): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The location of this field declaration.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### typeDef()

> **typeDef**(): [`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

The type of the field.

#### Returns

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

## See Also

- [Documentation Overview](./COMPASS.md)
