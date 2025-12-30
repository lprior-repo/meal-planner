---
id: ref/classes/changeset
title: "Class: Changeset"
category: ref
tags: ["ref", "file", "api", "directory", "typescript"]
---

# Class: Changeset

> **Context**: A comparison between two directories representing changes that can be applied.


A comparison between two directories representing changes that can be applied.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Changeset**(`ctx?`, `_id?`, `_export?`, `_isEmpty?`, `_sync?`): `Changeset`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`ChangesetID`](/reference/typescript/api/client.gen/type-aliases/ChangesetID)

#### \_export?

`string`

#### \_isEmpty?

`boolean`

#### \_sync?

[`ChangesetID`](/reference/typescript/api/client.gen/type-aliases/ChangesetID)

#### Returns

`Changeset`

#### Overrides

`BaseClient.constructor`

## Methods

### addedPaths()

> **addedPaths**(): `Promise`<`string`\[\]>

Files and directories that were added in the newer directory.

#### Returns

`Promise`<`string`\[\]>

---

### after()

> **after**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The newer/upper snapshot.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### asPatch()

> **asPatch**(): [`File`](/reference/typescript/api/client.gen/classes/File)

Return a Git-compatible patch of the changes

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### before()

> **before**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The older/lower snapshot to compare against.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### export()

> **export**(`path`): `Promise`<`string`\>

Applies the diff represented by this changeset to a path on the host.

#### Parameters

#### path

`string`

Location of the copied directory (e.g., "logs/").

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`ChangesetID`](/reference/typescript/api/client.gen/type-aliases/ChangesetID)\>

A unique identifier for this Changeset.

#### Returns

`Promise`<[`ChangesetID`](/reference/typescript/api/client.gen/type-aliases/ChangesetID)\>

---

### isEmpty()

> **isEmpty**(): `Promise`<`boolean`\>

Returns true if the changeset is empty (i.e. there are no changes).

#### Returns

`Promise`<`boolean`\>

---

### layer()

> **layer**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Return a snapshot containing only the created and modified files

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### modifiedPaths()

> **modifiedPaths**(): `Promise`<`string`\[\]>

Files and directories that existed before and were updated in the newer directory.

#### Returns

`Promise`<`string`\[\]>

---

### removedPaths()

> **removedPaths**(): `Promise`<`string`\[\]>

Files and directories that were removed. Directories are indicated by a trailing slash, and their child paths are not included.

#### Returns

`Promise`<`string`\[\]>

---

### sync()

> **sync**(): `Promise`<`Changeset`\>

Force evaluation in the engine.

#### Returns

`Promise`<`Changeset`\>

## See Also

- [Documentation Overview](./COMPASS.md)
