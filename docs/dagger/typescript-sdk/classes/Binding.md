# Class: Binding

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Binding**(`ctx?`, `_id?`, `_asString?`, `_digest?`, `_isNull?`, `_name?`, `_typeName?`): `Binding`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`BindingID`](/reference/typescript/api/client.gen/type-aliases/BindingID)

##### \_asString?

`string`

##### \_digest?

`string`

##### \_isNull?

`boolean`

##### \_name?

`string`

##### \_typeName?

`string`

#### Returns

`Binding`

#### Overrides

`BaseClient.constructor`

## Methods

### asAddress()

> **asAddress**(): [`Address`](/reference/typescript/api/client.gen/classes/Address)

Retrieve the binding value, as type Address

#### Returns

[`Address`](/reference/typescript/api/client.gen/classes/Address)

---

### asCacheVolume()

> **asCacheVolume**(): [`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

Retrieve the binding value, as type CacheVolume

#### Returns

[`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

---

### asChangeset()

> **asChangeset**(): [`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

Retrieve the binding value, as type Changeset

#### Returns

[`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

---

### asCheck()

> **asCheck**(): [`Check`](/reference/typescript/api/client.gen/classes/Check)

Retrieve the binding value, as type Check

#### Returns

[`Check`](/reference/typescript/api/client.gen/classes/Check)

---

### asCheckGroup()

> **asCheckGroup**(): [`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

Retrieve the binding value, as type CheckGroup

#### Returns

[`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

---

### asCloud()

> **asCloud**(): [`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

Retrieve the binding value, as type Cloud

#### Returns

[`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

---

### asContainer()

> **asContainer**(): [`Container`](/reference/typescript/api/client.gen/classes/Container)

Retrieve the binding value, as type Container

#### Returns

[`Container`](/reference/typescript/api/client.gen/classes/Container)

---

### asDirectory()

> **asDirectory**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Retrieve the binding value, as type Directory

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### asEnv()

> **asEnv**(): [`Env`](/reference/typescript/api/client.gen/classes/Env)

Retrieve the binding value, as type Env

#### Returns

[`Env`](/reference/typescript/api/client.gen/classes/Env)

---

### asEnvFile()

> **asEnvFile**(): [`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

Retrieve the binding value, as type EnvFile

#### Returns

[`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

---

### asFile()

> **asFile**(): [`File`](/reference/typescript/api/client.gen/classes/File)

Retrieve the binding value, as type File

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### asGitRef()

> **asGitRef**(): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Retrieve the binding value, as type GitRef

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### asGitRepository()

> **asGitRepository**(): [`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

Retrieve the binding value, as type GitRepository

#### Returns

[`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

---

### asJSONValue()

> **asJSONValue**(): [`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

Retrieve the binding value, as type JSONValue

#### Returns

[`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

---

### asModule()

> **asModule**(): [`Module_`](/reference/typescript/api/client.gen/classes/Module)

Retrieve the binding value, as type Module

#### Returns

[`Module_`](/reference/typescript/api/client.gen/classes/Module)

---

### asModuleConfigClient()

> **asModuleConfigClient**(): [`ModuleConfigClient`](/reference/typescript/api/client.gen/classes/ModuleConfigClient)

Retrieve the binding value, as type ModuleConfigClient

#### Returns

[`ModuleConfigClient`](/reference/typescript/api/client.gen/classes/ModuleConfigClient)

---

### asModuleSource()

> **asModuleSource**(): [`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

Retrieve the binding value, as type ModuleSource

#### Returns

[`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

---

### asSearchResult()

> **asSearchResult**(): [`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)

Retrieve the binding value, as type SearchResult

#### Returns

[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)

---

### asSearchSubmatch()

> **asSearchSubmatch**(): [`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)

Retrieve the binding value, as type SearchSubmatch

#### Returns

[`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)

---

### asSecret()

> **asSecret**(): [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Retrieve the binding value, as type Secret

#### Returns

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

---

### asService()

> **asService**(): [`Service`](/reference/typescript/api/client.gen/classes/Service)

Retrieve the binding value, as type Service

#### Returns

[`Service`](/reference/typescript/api/client.gen/classes/Service)

---

### asSocket()

> **asSocket**(): [`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Retrieve the binding value, as type Socket

#### Returns

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)

---

### asString()

> **asString**(): `Promise`<`string`\>

Returns the binding's string value

#### Returns

`Promise`<`string`\>

---

### digest()

> **digest**(): `Promise`<`string`\>

Returns the digest of the binding value

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`BindingID`](/reference/typescript/api/client.gen/type-aliases/BindingID)\>

A unique identifier for this Binding.

#### Returns

`Promise`<[`BindingID`](/reference/typescript/api/client.gen/type-aliases/BindingID)\>

---

### isNull()

> **isNull**(): `Promise`<`boolean`\>

Returns true if the binding is null

#### Returns

`Promise`<`boolean`\>

---

### name()

> **name**(): `Promise`<`string`\>

Returns the binding name

#### Returns

`Promise`<`string`\>

---

### typeName()

> **typeName**(): `Promise`<`string`\>

Returns the binding type

#### Returns

`Promise`<`string`\>
