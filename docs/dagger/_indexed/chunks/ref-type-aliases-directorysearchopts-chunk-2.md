---
doc_id: ref/type-aliases/directorysearchopts
chunk_id: ref/type-aliases/directorysearchopts#chunk-2
heading_path: ["directorysearchopts", "Properties"]
chunk_type: prose
tokens: 194
summary: "> `optional` **dotall**: `boolean`

Allow the ."
---
### dotall?

> `optional` **dotall**: `boolean`

Allow the . pattern to match newlines in multiline mode.

---

### filesOnly?

> `optional` **filesOnly**: `boolean`

Only return matching files, not lines and content

---

### globs?

> `optional` **globs**: `string`[]

Glob patterns to match (e.g., "*.md")

---

### insensitive?

> `optional` **insensitive**: `boolean`

Enable case-insensitive matching.

---

### limit?

> `optional` **limit**: `number`

Limit the number of results to return

---

### literal?

> `optional` **literal**: `boolean`

Interpret the pattern as a literal string instead of a regular expression.

---

### multiline?

> `optional` **multiline**: `boolean`

Enable searching across multiple lines.

---

### paths?

> `optional` **paths**: `string`[]

Directory or file paths to search

---

### pattern

> **pattern**: `string`

The text to match.

---

### skipHidden?

> `optional` **skipHidden**: `boolean`

Skip hidden files (files starting with .).

---

### skipIgnored?

> `optional` **skipIgnored**: `boolean`

Honor .gitignore, .ignore, and .rgignore files.
