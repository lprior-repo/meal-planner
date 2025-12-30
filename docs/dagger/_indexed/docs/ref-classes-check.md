---
id: ref/classes/check
title: "Class: Check"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: Check

> **Context**: > **new Check**(`ctx?`, `_id?`, `_completed?`, `_description?`, `_name?`, `_passed?`, `_resultEmoji?`): `Check`


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Check**(`ctx?`, `_id?`, `_completed?`, `_description?`, `_name?`, `_passed?`, `_resultEmoji?`): `Check`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`CheckID`](/reference/typescript/api/client.gen/type-aliases/CheckID)

#### \_completed?

`boolean`

#### \_description?

`string`

#### \_name?

`string`

#### \_passed?

`boolean`

#### \_resultEmoji?

`string`

#### Returns

`Check`

#### Overrides

`BaseClient.constructor`

## Methods

### completed()

> **completed**(): `Promise`<`boolean`\>

Whether the check completed

#### Returns

`Promise`<`boolean`\>

---

### description()

> **description**(): `Promise`<`string`\>

The description of the check

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`CheckID`](/reference/typescript/api/client.gen/type-aliases/CheckID)\>

A unique identifier for this Check.

#### Returns

`Promise`<[`CheckID`](/reference/typescript/api/client.gen/type-aliases/CheckID)\>

---

### name()

> **name**(): `Promise`<`string`\>

Return the fully qualified name of the check

#### Returns

`Promise`<`string`\>

---

### passed()

> **passed**(): `Promise`<`boolean`\>

Whether the check passed

#### Returns

`Promise`<`boolean`\>

---

### path()

> **path**(): `Promise`<`string`\[\]>

The path of the check within its module

#### Returns

`Promise`<`string`\[\]>

---

### resultEmoji()

> **resultEmoji**(): `Promise`<`string`\>

An emoji representing the result of the check

#### Returns

`Promise`<`string`\>

---

### run()

> **run**(): `Check`

Execute the check

#### Returns

`Check`

---

### with()

> **with**(`arg`): `Check`

Call the provided function with current Check.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `Check`

#### Returns

`Check`

## See Also

- [Documentation Overview](./COMPASS.md)
