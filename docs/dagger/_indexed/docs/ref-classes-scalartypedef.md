---
id: ref/classes/scalartypedef
title: "Class: ScalarTypeDef"
category: ref
tags: ["ref", "api", "typescript", "module", "cli"]
---

# Class: ScalarTypeDef

> **Context**: A definition of a custom scalar defined in a Module.


A definition of a custom scalar defined in a Module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new ScalarTypeDef**(`ctx?`, `_id?`, `_description?`, `_name?`, `_sourceModuleName?`): `ScalarTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`ScalarTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ScalarTypeDefID)

#### \_description?

`string`

#### \_name?

`string`

#### \_sourceModuleName?

`string`

#### Returns

`ScalarTypeDef`

#### Overrides

`BaseClient.constructor`

## Methods

### description()

> **description**(): `Promise`<`string`\>

A doc string for the scalar, if any.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`ScalarTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ScalarTypeDefID)\>

A unique identifier for this ScalarTypeDef.

#### Returns

`Promise`<[`ScalarTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ScalarTypeDefID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the scalar.

#### Returns

`Promise`<`string`\>

---

### sourceModuleName()

> **sourceModuleName**(): `Promise`<`string`\>

If this ScalarTypeDef is associated with a Module, the name of the module. Unset otherwise.

#### Returns

`Promise`<`string`\>

## See Also

- [Documentation Overview](./COMPASS.md)
