---
id: ref/classes/listtypedef
title: "Class: ListTypeDef"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: ListTypeDef

> **Context**: A definition of a list type in a Module.


A definition of a list type in a Module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new ListTypeDef**(`ctx?`, `_id?`): `ListTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`ListTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ListTypeDefID)

#### Returns

`ListTypeDef`

#### Overrides

`BaseClient.constructor`

## Methods

### elementTypeDef()

> **elementTypeDef**(): [`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

The type of the elements in the list.

#### Returns

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

---

### id()

> **id**(): `Promise`<[`ListTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ListTypeDefID)\>

A unique identifier for this ListTypeDef.

#### Returns

`Promise`<[`ListTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ListTypeDefID)\>

## See Also

- [Documentation Overview](./COMPASS.md)
