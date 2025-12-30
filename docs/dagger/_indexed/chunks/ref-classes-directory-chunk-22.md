---
doc_id: ref/classes/directory
chunk_id: ref/classes/directory#chunk-22
heading_path: ["directory", "Methods", "search()"]
chunk_type: prose
tokens: 48
summary: "> **search**(`opts?"
---
> **search**(`opts?`): `Promise`<[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)\[\]>

Searches for content matching the given regular expression or literal string.

Uses Rust regex syntax; escape literal ., \[, \], {, }, | with backslashes.

#### Parameters

#### opts?

[`DirectorySearchOpts`](/reference/typescript/api/client.gen/type-aliases/DirectorySearchOpts)

#### Returns

`Promise`<[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)\[\]>

---
