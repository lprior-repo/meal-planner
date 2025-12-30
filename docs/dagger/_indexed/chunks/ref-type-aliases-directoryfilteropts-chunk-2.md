---
doc_id: ref/type-aliases/directoryfilteropts
chunk_id: ref/type-aliases/directoryfilteropts#chunk-2
heading_path: ["directoryfilteropts", "Properties"]
chunk_type: prose
tokens: 88
summary: "> `optional` **exclude**: `string`[]

If set, paths matching one of these glob patterns is exclud..."
---
### exclude?

> `optional` **exclude**: `string`[]

If set, paths matching one of these glob patterns is excluded from the new snapshot. Example: ["node_modules/", ".git*", ".env"]

---

### gitignore?

> `optional` **gitignore**: `boolean`

If set, apply .gitignore rules when filtering the directory.

---

### include?

> `optional` **include**: `string`[]

If set, only paths matching one of these glob patterns is included in the new snapshot. Example: (e.g., ["app/", "package.*"]).
