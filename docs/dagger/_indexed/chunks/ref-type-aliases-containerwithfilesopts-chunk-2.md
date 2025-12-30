---
doc_id: ref/type-aliases/containerwithfilesopts
chunk_id: ref/type-aliases/containerwithfilesopts#chunk-2
heading_path: ["containerwithfilesopts", "Properties"]
chunk_type: prose
tokens: 108
summary: "> `optional` **expand**: `boolean`

Replace \"${VAR}\" or \"$VAR\" in the value of path according to ..."
---
### expand?

> `optional` **expand**: `boolean`

Replace "${VAR}" or "$VAR" in the value of path according to the current environment variables defined in the container (e.g. "/$VAR/foo.txt").

---

### owner?

> `optional` **owner**: `string`

A user:group to set for the files.

The user and group can either be an ID (1000:1000) or a name (foo:bar).

If the group is omitted, it defaults to the same as the user.

---

### permissions?

> `optional` **permissions**: `number`

Permission given to the copied files (e.g., 0600).
