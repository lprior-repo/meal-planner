---
doc_id: ref/classes/file
chunk_id: ref/classes/file#chunk-4
heading_path: ["file", "Methods"]
chunk_type: prose
tokens: 624
summary: "> **asEnvFile**(`opts?"
---
### asEnvFile()

> **asEnvFile**(`opts?`): [`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

Parse as an env file

#### Parameters

#### opts?

[`FileAsEnvFileOpts`](/reference/typescript/api/client.gen/type-aliases/FileAsEnvFileOpts)

#### Returns

[`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

---

### chown()

> **chown**(`owner`): `File`

Change the owner of the file recursively.

#### Parameters

#### owner

`string`

A user:group to set for the file.

The user and group must be an ID (1000:1000), not a name (foo:bar).

If the group is omitted, it defaults to the same as the user.

#### Returns

`File`

---

### contents()

> **contents**(`opts?`): `Promise`<`string`\>

Retrieves the contents of the file.

#### Parameters

#### opts?

[`FileContentsOpts`](/reference/typescript/api/client.gen/type-aliases/FileContentsOpts)

#### Returns

`Promise`<`string`\>

---

### digest()

> **digest**(`opts?`): `Promise`<`string`\>

Return the file's digest. The format of the digest is not guaranteed to be stable between releases of Dagger. It is guaranteed to be stable between invocations of the same Dagger engine.

#### Parameters

#### opts?

[`FileDigestOpts`](/reference/typescript/api/client.gen/type-aliases/FileDigestOpts)

#### Returns

`Promise`<`string`\>

---

### export()

> **export**(`path`, `opts?`): `Promise`<`string`\>

Writes the file to a file path on the host.

#### Parameters

#### path

`string`

Location of the written directory (e.g., "output.txt").

#### opts?

[`FileExportOpts`](/reference/typescript/api/client.gen/type-aliases/FileExportOpts)

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`FileID`](/reference/typescript/api/client.gen/type-aliases/FileID)\>

A unique identifier for this File.

#### Returns

`Promise`<[`FileID`](/reference/typescript/api/client.gen/type-aliases/FileID)\>

---

### name()

> **name**(): `Promise`<`string`\>

Retrieves the name of the file.

#### Returns

`Promise`<`string`\>

---

### search()

> **search**(`pattern`, `opts?`): `Promise`<[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)\[\]>

Searches for content matching the given regular expression or literal string.

Uses Rust regex syntax; escape literal ., \[, \], {, }, | with backslashes.

#### Parameters

#### pattern

`string`

The text to match.

#### opts?

[`FileSearchOpts`](/reference/typescript/api/client.gen/type-aliases/FileSearchOpts)

#### Returns

`Promise`<[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)\[\]>

---

### size()

> **size**(): `Promise`<`number`\>

Retrieves the size of the file, in bytes.

#### Returns

`Promise`<`number`\>

---

### sync()

> **sync**(): `Promise`<`File`\>

Force evaluation in the engine.

#### Returns

`Promise`<`File`\>

---

### with()

> **with**(`arg`): `File`

Call the provided function with current File.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `File`

#### Returns

`File`

---

### withName()

> **withName**(`name`): `File`

Retrieves this file with its name set to the given name.

#### Parameters

#### name

`string`

Name to set file to.

#### Returns

`File`

---

### withReplaced()

> **withReplaced**(`search`, `replacement`, `opts?`): `File`

Retrieves the file with content replaced with the given text.

If 'all' is true, all occurrences of the pattern will be replaced.

If 'firstAfter' is specified, only the first match starting at the specified line will be replaced.

If neither are specified, and there are multiple matches for the pattern, this will error.

If there are no matches for the pattern, this will error.

#### Parameters

#### search

`string`

The text to match.

#### replacement

`string`

The text to match.

#### opts?

[`FileWithReplacedOpts`](/reference/typescript/api/client.gen/type-aliases/FileWithReplacedOpts)

#### Returns

`File`

---

### withTimestamps()

> **withTimestamps**(`timestamp`): `File`

Retrieves this file with its created/modified timestamps set to the given time.

#### Parameters

#### timestamp

`number`

Timestamp to set dir/files in.

Formatted in seconds following Unix epoch (e.g., 1672531199).

#### Returns

`File`
