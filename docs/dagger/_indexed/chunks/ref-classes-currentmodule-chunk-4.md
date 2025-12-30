---
doc_id: ref/classes/currentmodule
chunk_id: ref/classes/currentmodule#chunk-4
heading_path: ["currentmodule", "Methods"]
chunk_type: prose
tokens: 277
summary: "> **dependencies**(): `Promise`<[`Module_`](/reference/typescript/api/client."
---
### dependencies()

> **dependencies**(): `Promise`<[`Module_`](/reference/typescript/api/client.gen/classes/Module)\[\]>

The dependencies of the module.

#### Returns

`Promise`<[`Module_`](/reference/typescript/api/client.gen/classes/Module)\[\]>

---

### generatedContextDirectory()

> **generatedContextDirectory**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The generated files and directories made on top of the module source's context directory.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### id()

> **id**(): `Promise`<[`CurrentModuleID`](/reference/typescript/api/client.gen/type-aliases/CurrentModuleID)\>

A unique identifier for this CurrentModule.

#### Returns

`Promise`<[`CurrentModuleID`](/reference/typescript/api/client.gen/type-aliases/CurrentModuleID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the module being executed in

#### Returns

`Promise`<`string`\>

---

### source()

> **source**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The directory containing the module's source code loaded into the engine (plus any generated code that may have been created).

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### workdir()

> **workdir**(`path`, `opts?`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Load a directory from the module's scratch working directory, including any changes that may have been made to it during module function execution.

#### Parameters

#### path

`string`

Location of the directory to access (e.g., ".").

#### opts?

[`CurrentModuleWorkdirOpts`](/reference/typescript/api/client.gen/type-aliases/CurrentModuleWorkdirOpts)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### workdirFile()

> **workdirFile**(`path`): [`File`](/reference/typescript/api/client.gen/classes/File)

Load a file from the module's scratch working directory, including any changes that may have been made to it during module function execution.Load a file from the module's scratch working directory, including any changes that may have been made to it during module function execution.

#### Parameters

#### path

`string`

Location of the file to retrieve (e.g., "README.md").

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)
