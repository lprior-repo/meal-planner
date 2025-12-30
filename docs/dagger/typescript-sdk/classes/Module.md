# Class: Module\_

A Dagger module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Module\_**(`ctx?`, `_id?`, `_description?`, `_name?`, `_serve?`, `_sync?`): `Module_`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`ModuleID`](/reference/typescript/api/client.gen/type-aliases/ModuleID)

##### \_description?

`string`

##### \_name?

`string`

##### \_serve?

[`Void`](/reference/typescript/api/client.gen/type-aliases/Void)

##### \_sync?

[`ModuleID`](/reference/typescript/api/client.gen/type-aliases/ModuleID)

#### Returns

`Module_`

#### Overrides

`BaseClient.constructor`

## Methods

### check()

> **check**(`name`): [`Check`](/reference/typescript/api/client.gen/classes/Check)

**`Experimental`**

Return the check defined by the module with the given name. Must match to exactly one check.

#### Parameters

##### name

`string`

The name of the check to retrieve

#### Returns

[`Check`](/reference/typescript/api/client.gen/classes/Check)

---

### checks()

> **checks**(`opts?`): [`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

**`Experimental`**

Return all checks defined by the module

#### Parameters

##### opts?

[`ModuleChecksOpts`](/reference/typescript/api/client.gen/type-aliases/ModuleChecksOpts)

#### Returns

[`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

---

### dependencies()

> **dependencies**(): `Promise`<`Module_`\[\]>

The dependencies of the module.

#### Returns

`Promise`<`Module_`\[\]>

---

### description()

> **description**(): `Promise`<`string`\>

The doc string of the module, if any

#### Returns

`Promise`<`string`\>

---

### enums()

> **enums**(): `Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

Enumerations served by this module.

#### Returns

`Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

---

### generatedContextDirectory()

> **generatedContextDirectory**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The generated files and directories made on top of the module source's context directory.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### id()

> **id**(): `Promise`<[`ModuleID`](/reference/typescript/api/client.gen/type-aliases/ModuleID)\>

A unique identifier for this Module.

#### Returns

`Promise`<[`ModuleID`](/reference/typescript/api/client.gen/type-aliases/ModuleID)\>

---

### interfaces()

> **interfaces**(): `Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

Interfaces served by this module.

#### Returns

`Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

---

### introspectionSchemaJSON()

> **introspectionSchemaJSON**(): [`File`](/reference/typescript/api/client.gen/classes/File)

The introspection schema JSON file for this module.

This file represents the schema visible to the module's source code, including all core types and those from the dependencies.

Note: this is in the context of a module, so some core types may be hidden.

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### name()

> **name**(): `Promise`<`string`\>

The name of the module

#### Returns

`Promise`<`string`\>

---

### objects()

> **objects**(): `Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

Objects served by this module.

#### Returns

`Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

---

### runtime()

> **runtime**(): [`Container`](/reference/typescript/api/client.gen/classes/Container)

The container that runs the module's entrypoint. It will fail to execute if the module doesn't compile.

#### Returns

[`Container`](/reference/typescript/api/client.gen/classes/Container)

---

### sdk()

> **sdk**(): [`SDKConfig`](/reference/typescript/api/client.gen/classes/SDKConfig)

The SDK config used by this module.

#### Returns

[`SDKConfig`](/reference/typescript/api/client.gen/classes/SDKConfig)

---

### serve()

> **serve**(`opts?`): `Promise`<`void`\>

Serve a module's API in the current session.

Note: this can only be called once per session. In the future, it could return a stream or service to remove the side effect.

#### Parameters

##### opts?

[`ModuleServeOpts`](/reference/typescript/api/client.gen/type-aliases/ModuleServeOpts)

#### Returns

`Promise`<`void`\>

---

### source()

> **source**(): [`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

The source for the module.

#### Returns

[`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

---

### sync()

> **sync**(): `Promise`<`Module_`\>

Forces evaluation of the module, including any loading into the engine and associated validation.

#### Returns

`Promise`<`Module_`\>

---

### userDefaults()

> **userDefaults**(): [`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

User-defined default values, loaded from local .env files.

#### Returns

[`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

---

### with()

> **with**(`arg`): `Module_`

Call the provided function with current Module.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

##### arg

(`param`) => `Module_`

#### Returns

`Module_`

---

### withDescription()

> **withDescription**(`description`): `Module_`

Retrieves the module with the given description

#### Parameters

##### description

`string`

The description to set

#### Returns

`Module_`

---

### withEnum()

> **withEnum**(`enum_`): `Module_`

This module plus the given Enum type and associated values

#### Parameters

##### enum\_

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

#### Returns

`Module_`

---

### withInterface()

> **withInterface**(`iface`): `Module_`

This module plus the given Interface type and associated functions

#### Parameters

##### iface

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

#### Returns

`Module_`

---

### withObject()

> **withObject**(`object`): `Module_`

This module plus the given Object type and associated functions.

#### Parameters

##### object

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

#### Returns

`Module_`
