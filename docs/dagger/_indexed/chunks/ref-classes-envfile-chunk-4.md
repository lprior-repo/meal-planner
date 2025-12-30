---
doc_id: ref/classes/envfile
chunk_id: ref/classes/envfile#chunk-4
heading_path: ["envfile", "Methods"]
chunk_type: prose
tokens: 307
summary: "> **asFile**(): [`File`](/reference/typescript/api/client."
---
### asFile()

> **asFile**(): [`File`](/reference/typescript/api/client.gen/classes/File)

Return as a file

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### exists()

> **exists**(`name`): `Promise`<`boolean`\>

Check if a variable exists

#### Parameters

#### name

`string`

Variable name

#### Returns

`Promise`<`boolean`\>

---

### get()

> **get**(`name`, `opts?`): `Promise`<`string`\>

Lookup a variable (last occurrence wins) and return its value, or an empty string

#### Parameters

#### name

`string`

Variable name

#### opts?

[`EnvFileGetOpts`](/reference/typescript/api/client.gen/type-aliases/EnvFileGetOpts)

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`EnvFileID`](/reference/typescript/api/client.gen/type-aliases/EnvFileID)\>

A unique identifier for this EnvFile.

#### Returns

`Promise`<[`EnvFileID`](/reference/typescript/api/client.gen/type-aliases/EnvFileID)\>

---

### namespace\_()

> **namespace\_**(`prefix`): `EnvFile`

Filters variables by prefix and removes the pref from keys. Variables without the prefix are excluded. For example, with the prefix "MY\_APP\_" and variables: MY\_APP\_TOKEN=topsecret MY\_APP\_NAME=hello FOO=bar the resulting environment will contain: TOKEN=topsecret NAME=hello

#### Parameters

#### prefix

`string`

The prefix to filter by

#### Returns

`EnvFile`

---

### variables()

> **variables**(`opts?`): `Promise`<[`EnvVariable`](/reference/typescript/api/client.gen/classes/EnvVariable)\[\]>

Return all variables

#### Parameters

#### opts?

[`EnvFileVariablesOpts`](/reference/typescript/api/client.gen/type-aliases/EnvFileVariablesOpts)

#### Returns

`Promise`<[`EnvVariable`](/reference/typescript/api/client.gen/classes/EnvVariable)\[\]>

---

### with()

> **with**(`arg`): `EnvFile`

Call the provided function with current EnvFile.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `EnvFile`

#### Returns

`EnvFile`

---

### withoutVariable()

> **withoutVariable**(`name`): `EnvFile`

Remove all occurrences of the named variable

#### Parameters

#### name

`string`

Variable name

#### Returns

`EnvFile`

---

### withVariable()

> **withVariable**(`name`, `value`): `EnvFile`

Add a variable

#### Parameters

#### name

`string`

Variable name

#### value

`string`

Variable value

#### Returns

`EnvFile`
