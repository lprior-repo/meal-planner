---
doc_id: ref/classes/changeset
chunk_id: ref/classes/changeset#chunk-4
heading_path: ["changeset", "Methods"]
chunk_type: prose
tokens: 280
summary: "> **addedPaths**(): `Promise`<`string`\[\]>

Files and directories that were added in the newer d..."
---
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
