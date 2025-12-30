---
doc_id: ref/type-aliases/directorywithfileopts
chunk_id: ref/type-aliases/directorywithfileopts#chunk-2
heading_path: ["directorywithfileopts", "Properties"]
chunk_type: prose
tokens: 75
summary: "> `optional` **owner**: `string`

A user:group to set for the copied directory and its contents."
---
### owner?

> `optional` **owner**: `string`

A user:group to set for the copied directory and its contents.

The user and group must be an ID (1000:1000), not a name (foo:bar).

If the group is omitted, it defaults to the same as the user.

---

### permissions?

> `optional` **permissions**: `number`

Permission given to the copied file (e.g., 0600).
