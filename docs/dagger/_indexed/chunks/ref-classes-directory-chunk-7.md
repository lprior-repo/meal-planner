---
doc_id: ref/classes/directory
chunk_id: ref/classes/directory#chunk-7
heading_path: ["directory", "Methods", "changes()"]
chunk_type: prose
tokens: 66
summary: "> **changes**(`from`): [`Changeset`](/reference/typescript/api/client."
---
> **changes**(`from`): [`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

Return the difference between this directory and another directory, typically an older snapshot.

The difference is encoded as a changeset, which also tracks removed files, and can be applied to other directories.

#### Parameters

#### from

`Directory`

The base directory snapshot to compare against

#### Returns

[`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

---
