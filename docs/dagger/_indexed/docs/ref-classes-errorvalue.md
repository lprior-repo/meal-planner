---
id: ref/classes/errorvalue
title: "Class: ErrorValue"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: ErrorValue

> **Context**: > **new ErrorValue**(`ctx?`, `_id?`, `_name?`, `_value?`): `ErrorValue`


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new ErrorValue**(`ctx?`, `_id?`, `_name?`, `_value?`): `ErrorValue`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`ErrorValueID`](/reference/typescript/api/client.gen/type-aliases/ErrorValueID)

#### \_name?

`string`

#### \_value?

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

#### Returns

`ErrorValue`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`ErrorValueID`](/reference/typescript/api/client.gen/type-aliases/ErrorValueID)\>

A unique identifier for this ErrorValue.

#### Returns

`Promise`<[`ErrorValueID`](/reference/typescript/api/client.gen/type-aliases/ErrorValueID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the value.

#### Returns

`Promise`<`string`\>

---

### value()

> **value**(): `Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

The value.

#### Returns

`Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

## See Also

- [Documentation Overview](./COMPASS.md)
