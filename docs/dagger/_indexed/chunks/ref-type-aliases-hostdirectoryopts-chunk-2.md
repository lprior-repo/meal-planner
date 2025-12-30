---
doc_id: ref/type-aliases/hostdirectoryopts
chunk_id: ref/type-aliases/hostdirectoryopts#chunk-2
heading_path: ["hostdirectoryopts", "Properties"]
chunk_type: prose
tokens: 86
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

### noCache?

> `optional` **noCache**: `boolean`

If true, the directory will always be reloaded from the host.
