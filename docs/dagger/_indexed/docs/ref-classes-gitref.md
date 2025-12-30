---
id: ref/classes/gitref
title: "Class: GitRef"
category: ref
tags: ["ref", "api", "directory", "git", "typescript"]
---

# Class: GitRef

> **Context**: A git ref (tag, branch, or commit).


A git ref (tag, branch, or commit).

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new GitRef**(`ctx?`, `_id?`, `_commit?`, `_ref?`): `GitRef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`GitRefID`](/reference/typescript/api/client.gen/type-aliases/GitRefID)

#### \_commit?

`string`

#### \_ref?

`string`

#### Returns

`GitRef`

#### Overrides

`BaseClient.constructor`

## Methods

### commit()

> **commit**(): `Promise`<`string`\>

The resolved commit id at this ref.

#### Returns

`Promise`<`string`\>

---

### commonAncestor()

> **commonAncestor**(`other`): `GitRef`

Find the best common ancestor between this ref and another ref.

#### Parameters

#### other

`GitRef`

The other ref to compare against.

#### Returns

`GitRef`

---

### id()

> **id**(): `Promise`<[`GitRefID`](/reference/typescript/api/client.gen/type-aliases/GitRefID)\>

A unique identifier for this GitRef.

#### Returns

`Promise`<[`GitRefID`](/reference/typescript/api/client.gen/type-aliases/GitRefID)\>

---

### ref()

> **ref**(): `Promise`<`string`\>

The resolved ref name at this ref.

#### Returns

`Promise`<`string`\>

---

### tree()

> **tree**(`opts?`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The filesystem tree at this ref.

#### Parameters

#### opts?

[`GitRefTreeOpts`](/reference/typescript/api/client.gen/type-aliases/GitRefTreeOpts)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### with()

> **with**(`arg`): `GitRef`

Call the provided function with current GitRef.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `GitRef`

#### Returns

`GitRef`

## See Also

- [Documentation Overview](./COMPASS.md)
