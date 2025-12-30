---
id: ref/classes/searchsubmatch
title: "Class: SearchSubmatch"
category: ref
tags: ["ref", "api", "type", "typescript", "cli"]
---

# Class: SearchSubmatch

> **Context**: > **new SearchSubmatch**(`ctx?`, `_id?`, `_end?`, `_start?`, `_text?`): `SearchSubmatch`


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new SearchSubmatch**(`ctx?`, `_id?`, `_end?`, `_start?`, `_text?`): `SearchSubmatch`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`SearchSubmatchID`](/reference/typescript/api/client.gen/type-aliases/SearchSubmatchID)

#### \_end?

`number`

#### \_start?

`number`

#### \_text?

`string`

#### Returns

`SearchSubmatch`

#### Overrides

`BaseClient.constructor`

## Methods

### end()

> **end**(): `Promise`<`number`\>

The match's end offset within the matched lines.

#### Returns

`Promise`<`number`\>

---

### id()

> **id**(): `Promise`<[`SearchSubmatchID`](/reference/typescript/api/client.gen/type-aliases/SearchSubmatchID)\>

A unique identifier for this SearchSubmatch.

#### Returns

`Promise`<[`SearchSubmatchID`](/reference/typescript/api/client.gen/type-aliases/SearchSubmatchID)\>

---

### start()

> **start**(): `Promise`<`number`\>

The match's start offset within the matched lines.

#### Returns

`Promise`<`number`\>

---

### text()

> **text**(): `Promise`<`string`\>

The matched text.

#### Returns

`Promise`<`string`\>

## See Also

- [Documentation Overview](./COMPASS.md)
