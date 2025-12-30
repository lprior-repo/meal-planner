---
id: ref/classes/checkgroup
title: "Class: CheckGroup"
category: ref
tags: ["ref", "file", "api", "typescript", "cli"]
---

# Class: CheckGroup

> **Context**: > **new CheckGroup**(`ctx?`, `_id?`): `CheckGroup`


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new CheckGroup**(`ctx?`, `_id?`): `CheckGroup`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`CheckGroupID`](/reference/typescript/api/client.gen/type-aliases/CheckGroupID)

#### Returns

`CheckGroup`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`CheckGroupID`](/reference/typescript/api/client.gen/type-aliases/CheckGroupID)\>

A unique identifier for this CheckGroup.

#### Returns

`Promise`<[`CheckGroupID`](/reference/typescript/api/client.gen/type-aliases/CheckGroupID)\>

---

### list()

> **list**(): `Promise`<[`Check`](/reference/typescript/api/client.gen/classes/Check)\[\]>

Return a list of individual checks and their details

#### Returns

`Promise`<[`Check`](/reference/typescript/api/client.gen/classes/Check)\[\]>

---

### report()

> **report**(): [`File`](/reference/typescript/api/client.gen/classes/File)

Generate a markdown report

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### run()

> **run**(): `CheckGroup`

Execute all selected checks

#### Returns

`CheckGroup`

---

### with()

> **with**(`arg`): `CheckGroup`

Call the provided function with current CheckGroup.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `CheckGroup`

#### Returns

`CheckGroup`

## See Also

- [Documentation Overview](./COMPASS.md)
