---
doc_id: ref/type-aliases/directorywithdirectoryopts
chunk_id: ref/type-aliases/directorywithdirectoryopts#chunk-2
heading_path: ["directorywithdirectoryopts", "Properties"]
chunk_type: prose
tokens: 120
summary: "> `optional` **exclude**: `string`[]

Exclude artifacts that match the given pattern (e."
---
### exclude?

> `optional` **exclude**: `string`[]

Exclude artifacts that match the given pattern (e.g., ["node_modules/", ".git*"]).

---

### gitignore?

> `optional` **gitignore**: `boolean`

Apply .gitignore filter rules inside the directory

---

### include?

> `optional` **include**: `string`[]

Include only artifacts that match the given pattern (e.g., ["app/", "package.*"]).

---

### owner?

> `optional` **owner**: `string`

A user:group to set for the copied directory and its contents.

The user and group must be an ID (1000:1000), not a name (foo:bar).

If the group is omitted, it defaults to the same as the user.
