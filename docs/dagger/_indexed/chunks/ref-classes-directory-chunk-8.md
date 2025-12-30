---
doc_id: ref/classes/directory
chunk_id: ref/classes/directory#chunk-8
heading_path: ["directory", "Methods", "chown()"]
chunk_type: prose
tokens: 92
summary: "> **chown**(`path`, `owner`): `Directory`

Change the owner of the directory contents recursively."
---
> **chown**(`path`, `owner`): `Directory`

Change the owner of the directory contents recursively.

#### Parameters

#### path

`string`

Path of the directory to change ownership of (e.g., "/").

#### owner

`string`

A user:group to set for the mounted directory and its contents.

The user and group must be an ID (1000:1000), not a name (foo:bar).

If the group is omitted, it defaults to the same as the user.

#### Returns

`Directory`

---
