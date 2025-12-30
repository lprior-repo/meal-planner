---
id: ref/classes/env
title: "Class: Env"
category: ref
tags: ["ref", "cache", "module", "function", "container"]
---

# Class: Env

> **Context**: > **new Env**(`ctx?`, `_id?`): `Env`


## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Env**(`ctx?`, `_id?`): `Env`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

#### ctx?

`Context`

#### \_id?

[`EnvID`](/reference/typescript/api/client.gen/type-aliases/EnvID)

#### Returns

`Env`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`EnvID`](/reference/typescript/api/client.gen/type-aliases/EnvID)\>

A unique identifier for this Env.

#### Returns

`Promise`<[`EnvID`](/reference/typescript/api/client.gen/type-aliases/EnvID)\>

---

### input()

> **input**(`name`): [`Binding`](/reference/typescript/api/client.gen/classes/Binding)

Retrieves an input binding by name

#### Parameters

#### name

`string`

#### Returns

[`Binding`](/reference/typescript/api/client.gen/classes/Binding)

---

### inputs()

> **inputs**(): `Promise`<[`Binding`](/reference/typescript/api/client.gen/classes/Binding)\[\]>

Returns all input bindings provided to the environment

#### Returns

`Promise`<[`Binding`](/reference/typescript/api/client.gen/classes/Binding)\[\]>

---

### output()

> **output**(`name`): [`Binding`](/reference/typescript/api/client.gen/classes/Binding)

Retrieves an output binding by name

#### Parameters

#### name

`string`

#### Returns

[`Binding`](/reference/typescript/api/client.gen/classes/Binding)

---

### outputs()

> **outputs**(): `Promise`<[`Binding`](/reference/typescript/api/client.gen/classes/Binding)\[\]>

Returns all declared output bindings for the environment

#### Returns

`Promise`<[`Binding`](/reference/typescript/api/client.gen/classes/Binding)\[\]>

---

### with()

> **with**(`arg`): `Env`

Call the provided function with current Env.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `Env`

#### Returns

`Env`

---

### withAddressInput()

> **withAddressInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Address in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Address`](/reference/typescript/api/client.gen/classes/Address)

The Address value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withAddressOutput()

> **withAddressOutput**(`name`, `description`): `Env`

Declare a desired Address output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withCacheVolumeInput()

> **withCacheVolumeInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type CacheVolume in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

The CacheVolume value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withCacheVolumeOutput()

> **withCacheVolumeOutput**(`name`, `description`): `Env`

Declare a desired CacheVolume output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withChangesetInput()

> **withChangesetInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Changeset in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

The Changeset value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withChangesetOutput()

> **withChangesetOutput**(`name`, `description`): `Env`

Declare a desired Changeset output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withCheckGroupInput()

> **withCheckGroupInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type CheckGroup in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

The CheckGroup value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withCheckGroupOutput()

> **withCheckGroupOutput**(`name`, `description`): `Env`

Declare a desired CheckGroup output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withCheckInput()

> **withCheckInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Check in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Check`](/reference/typescript/api/client.gen/classes/Check)

The Check value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withCheckOutput()

> **withCheckOutput**(`name`, `description`): `Env`

Declare a desired Check output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withCloudInput()

> **withCloudInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Cloud in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

The Cloud value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withCloudOutput()

> **withCloudOutput**(`name`, `description`): `Env`

Declare a desired Cloud output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withContainerInput()

> **withContainerInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Container in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Container`](/reference/typescript/api/client.gen/classes/Container)

The Container value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withContainerOutput()

> **withContainerOutput**(`name`, `description`): `Env`

Declare a desired Container output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withCurrentModule()

> **withCurrentModule**(): `Env`

Installs the current module into the environment, exposing its functions to the model

Contextual path arguments will be populated using the environment's workspace.

#### Returns

`Env`

---

### withDirectoryInput()

> **withDirectoryInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Directory in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The Directory value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withDirectoryOutput()

> **withDirectoryOutput**(`name`, `description`): `Env`

Declare a desired Directory output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withEnvFileInput()

> **withEnvFileInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type EnvFile in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

The EnvFile value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withEnvFileOutput()

> **withEnvFileOutput**(`name`, `description`): `Env`

Declare a desired EnvFile output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withEnvInput()

> **withEnvInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Env in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

`Env`

The Env value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withEnvOutput()

> **withEnvOutput**(`name`, `description`): `Env`

Declare a desired Env output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withFileInput()

> **withFileInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type File in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`File`](/reference/typescript/api/client.gen/classes/File)

The File value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withFileOutput()

> **withFileOutput**(`name`, `description`): `Env`

Declare a desired File output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withGitRefInput()

> **withGitRefInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type GitRef in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

The GitRef value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withGitRefOutput()

> **withGitRefOutput**(`name`, `description`): `Env`

Declare a desired GitRef output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withGitRepositoryInput()

> **withGitRepositoryInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type GitRepository in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

The GitRepository value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withGitRepositoryOutput()

> **withGitRepositoryOutput**(`name`, `description`): `Env`

Declare a desired GitRepository output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withJSONValueInput()

> **withJSONValueInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type JSONValue in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

The JSONValue value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withJSONValueOutput()

> **withJSONValueOutput**(`name`, `description`): `Env`

Declare a desired JSONValue output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withModule()

> **withModule**(`module_`): `Env`

Installs a module into the environment, exposing its functions to the model

Contextual path arguments will be populated using the environment's workspace.

#### Parameters

#### module\_

[`Module_`](/reference/typescript/api/client.gen/classes/Module)

#### Returns

`Env`

---

### withModuleConfigClientInput()

> **withModuleConfigClientInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type ModuleConfigClient in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`ModuleConfigClient`](/reference/typescript/api/client.gen/classes/ModuleConfigClient)

The ModuleConfigClient value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withModuleConfigClientOutput()

> **withModuleConfigClientOutput**(`name`, `description`): `Env`

Declare a desired ModuleConfigClient output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withModuleInput()

> **withModuleInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Module in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Module_`](/reference/typescript/api/client.gen/classes/Module)

The Module value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withModuleOutput()

> **withModuleOutput**(`name`, `description`): `Env`

Declare a desired Module output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withModuleSourceInput()

> **withModuleSourceInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type ModuleSource in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

The ModuleSource value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withModuleSourceOutput()

> **withModuleSourceOutput**(`name`, `description`): `Env`

Declare a desired ModuleSource output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withoutOutputs()

> **withoutOutputs**(): `Env`

Returns a new environment without any outputs

#### Returns

`Env`

---

### withSearchResultInput()

> **withSearchResultInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type SearchResult in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)

The SearchResult value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withSearchResultOutput()

> **withSearchResultOutput**(`name`, `description`): `Env`

Declare a desired SearchResult output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withSearchSubmatchInput()

> **withSearchSubmatchInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type SearchSubmatch in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)

The SearchSubmatch value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withSearchSubmatchOutput()

> **withSearchSubmatchOutput**(`name`, `description`): `Env`

Declare a desired SearchSubmatch output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withSecretInput()

> **withSecretInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Secret in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

The Secret value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withSecretOutput()

> **withSecretOutput**(`name`, `description`): `Env`

Declare a desired Secret output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withServiceInput()

> **withServiceInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Service in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Service`](/reference/typescript/api/client.gen/classes/Service)

The Service value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withServiceOutput()

> **withServiceOutput**(`name`, `description`): `Env`

Declare a desired Service output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withSocketInput()

> **withSocketInput**(`name`, `value`, `description`): `Env`

Create or update a binding of type Socket in the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)

The Socket value to assign to the binding

#### description

`string`

The purpose of the input

#### Returns

`Env`

---

### withSocketOutput()

> **withSocketOutput**(`name`, `description`): `Env`

Declare a desired Socket output to be assigned in the environment

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

A description of the desired value of the binding

#### Returns

`Env`

---

### withStringInput()

> **withStringInput**(`name`, `value`, `description`): `Env`

Provides a string input binding to the environment

#### Parameters

#### name

`string`

The name of the binding

#### value

`string`

The string value to assign to the binding

#### description

`string`

The description of the input

#### Returns

`Env`

---

### withStringOutput()

> **withStringOutput**(`name`, `description`): `Env`

Declares a desired string output binding

#### Parameters

#### name

`string`

The name of the binding

#### description

`string`

The description of the output

#### Returns

`Env`

---

### withWorkspace()

> **withWorkspace**(`workspace`): `Env`

Returns a new environment with the provided workspace

#### Parameters

#### workspace

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The directory to set as the host filesystem

#### Returns

`Env`

---

### workspace()

> **workspace**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

## See Also

- [Documentation Overview](./COMPASS.md)
