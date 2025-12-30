---
doc_id: ref/type-aliases/functionwithargopts
chunk_id: ref/type-aliases/functionwithargopts#chunk-2
heading_path: ["functionwithargopts", "Properties"]
chunk_type: prose
tokens: 142
summary: "> `optional` **defaultPath**: `string`

If the argument is a Directory or File type, default to l..."
---
### defaultPath?

> `optional` **defaultPath**: `string`

If the argument is a Directory or File type, default to load path from context directory, relative to root directory.

---

### defaultValue?

> `optional` **defaultValue**: `JSON`

A default value to use for this argument if not explicitly set by the caller, if any

---

### deprecated?

> `optional` **deprecated**: `string`

If deprecated, the reason or migration path.

---

### description?

> `optional` **description**: `string`

A doc string for the argument, if any

---

### ignore?

> `optional` **ignore**: `string`[]

Patterns to ignore when loading the contextual argument value.

---

### sourceMap?

> `optional` **sourceMap**: `SourceMap`

The source map for the argument definition.
