# Class: Client

The root of the DAG.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Client**(`ctx?`, `_defaultPlatform?`, `_version?`): `Client`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_defaultPlatform?

[`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)

##### \_version?

`string`

#### Returns

`Client`

#### Overrides

`BaseClient.constructor`

## Methods

### address()

> **address**(`value`): [`Address`](/reference/typescript/api/client.gen/classes/Address)

initialize an address to load directories, containers, secrets or other object types.

#### Parameters

##### value

`string`

#### Returns

[`Address`](/reference/typescript/api/client.gen/classes/Address)

---

### cacheVolume()

> **cacheVolume**(`key`): [`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

Constructs a cache volume for a given cache key.

#### Parameters

##### key

`string`

A string identifier to target this cache volume (e.g., "modules-cache").

#### Returns

[`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

---

### cloud()

> **cloud**(): [`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

Dagger Cloud configuration and state

#### Returns

[`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

---

### container()

> **container**(`opts?`): [`Container`](/reference/typescript/api/client.gen/classes/Container)

Creates a scratch container, with no image or metadata.

To pull an image, follow up with the "from" function.

#### Parameters

##### opts?

[`ClientContainerOpts`](/reference/typescript/api/client.gen/type-aliases/ClientContainerOpts)

#### Returns

[`Container`](/reference/typescript/api/client.gen/classes/Container)

---

### currentEnv()

> **currentEnv**(): [`Env`](/reference/typescript/api/client.gen/classes/Env)

**`Experimental`**

Returns the current environment

When called from a function invoked via an LLM tool call, this will be the LLM's current environment, including any modifications made through calling tools. Env values returned by functions become the new environment for subsequent calls, and Changeset values returned by functions are applied to the environment's workspace.

When called from a module function outside of an LLM, this returns an Env with the current module installed, and with the current module's source directory as its workspace.

#### Returns

[`Env`](/reference/typescript/api/client.gen/classes/Env)

---

### currentFunctionCall()

> **currentFunctionCall**(): [`FunctionCall`](/reference/typescript/api/client.gen/classes/FunctionCall)

The FunctionCall context that the SDK caller is currently executing in.

If the caller is not currently executing in a function, this will return an error.

#### Returns

[`FunctionCall`](/reference/typescript/api/client.gen/classes/FunctionCall)

---

### currentModule()

> **currentModule**(): [`CurrentModule`](/reference/typescript/api/client.gen/classes/CurrentModule)

The module currently being served in the session, if any.

#### Returns

[`CurrentModule`](/reference/typescript/api/client.gen/classes/CurrentModule)

---

### currentTypeDefs()

> **currentTypeDefs**(): `Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

The TypeDef representations of the objects currently being served in the session.

#### Returns

`Promise`<[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)\[\]>

---

### defaultPlatform()

> **defaultPlatform**(): `Promise`<[`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)\>

The default platform of the engine.

#### Returns

`Promise`<[`Platform`](/reference/typescript/api/client.gen/type-aliases/Platform)\>

---

### directory()

> **directory**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Creates an empty directory.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### engine()

> **engine**(): [`Engine`](/reference/typescript/api/client.gen/classes/Engine)

The Dagger engine container configuration and state

#### Returns

[`Engine`](/reference/typescript/api/client.gen/classes/Engine)

---

### env()

> **env**(`opts?`): [`Env`](/reference/typescript/api/client.gen/classes/Env)

**`Experimental`**

Initializes a new environment

#### Parameters

##### opts?

[`ClientEnvOpts`](/reference/typescript/api/client.gen/type-aliases/ClientEnvOpts)

#### Returns

[`Env`](/reference/typescript/api/client.gen/classes/Env)

---

### envFile()

> **envFile**(`opts?`): [`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

Initialize an environment file

#### Parameters

##### opts?

[`ClientEnvFileOpts`](/reference/typescript/api/client.gen/type-aliases/ClientEnvFileOpts)

#### Returns

[`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

---

### error()

> **error**(`message`): [`Error`](/reference/typescript/api/client.gen/classes/Error)

Create a new error.

#### Parameters

##### message

`string`

A brief description of the error.

#### Returns

[`Error`](/reference/typescript/api/client.gen/classes/Error)

---

### file()

> **file**(`name`, `contents`, `opts?`): [`File`](/reference/typescript/api/client.gen/classes/File)

Creates a file with the specified contents.

#### Parameters

##### name

`string`

Name of the new file. Example: "foo.txt"

##### contents

`string`

Contents of the new file. Example: "Hello world!"

##### opts?

[`ClientFileOpts`](/reference/typescript/api/client.gen/type-aliases/ClientFileOpts)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### function\_()

> **function\_**(`name`, `returnType`): [`Function_`](/reference/typescript/api/client.gen/classes/Function)

Creates a function.

#### Parameters

##### name

`string`

Name of the function, in its original format from the implementation language.

##### returnType

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

Return type of the function.

#### Returns

[`Function_`](/reference/typescript/api/client.gen/classes/Function)

---

### generatedCode()

> **generatedCode**(`code`): [`GeneratedCode`](/reference/typescript/api/client.gen/classes/GeneratedCode)

Create a code generation result, given a directory containing the generated code.

#### Parameters

##### code

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

#### Returns

[`GeneratedCode`](/reference/typescript/api/client.gen/classes/GeneratedCode)

---

### getGQLClient()

> **getGQLClient**(): `GraphQLClient`

Get the Raw GraphQL client.

#### Returns

`GraphQLClient`

---

### git()

> **git**(`url`, `opts?`): [`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

Queries a Git repository.

#### Parameters

##### url

`string`

URL of the git repository.

Can be formatted as `https://{host}/{owner}/{repo}`, `git@{host}:{owner}/{repo}`.

Suffix ".git" is optional.

##### opts?

[`ClientGitOpts`](/reference/typescript/api/client.gen/type-aliases/ClientGitOpts)

#### Returns

[`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

---

### host()

> **host**(): [`Host`](/reference/typescript/api/client.gen/classes/Host)

Queries the host environment.

#### Returns

[`Host`](/reference/typescript/api/client.gen/classes/Host)

---

### http()

> **http**(`url`, `opts?`): [`File`](/reference/typescript/api/client.gen/classes/File)

Returns a file containing an http remote url content.

#### Parameters

##### url

`string`

HTTP url to get the content from (e.g., "https://docs.dagger.io").

##### opts?

[`ClientHttpOpts`](/reference/typescript/api/client.gen/type-aliases/ClientHttpOpts)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### json()

> **json**(): [`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

Initialize a JSON value

#### Returns

[`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

---

### llm()

> **llm**(`opts?`): [`LLM`](/reference/typescript/api/client.gen/classes/LLM)

**`Experimental`**

Initialize a Large Language Model (LLM)

#### Parameters

##### opts?

[`ClientLlmOpts`](/reference/typescript/api/client.gen/type-aliases/ClientLlmOpts)

#### Returns

[`LLM`](/reference/typescript/api/client.gen/classes/LLM)

---

### loadAddressFromID()

> **loadAddressFromID**(`id`): [`Address`](/reference/typescript/api/client.gen/classes/Address)

Load a Address from its ID.

#### Parameters

##### id

[`AddressID`](/reference/typescript/api/client.gen/type-aliases/AddressID)

#### Returns

[`Address`](/reference/typescript/api/client.gen/classes/Address)

---

### loadBindingFromID()

> **loadBindingFromID**(`id`): [`Binding`](/reference/typescript/api/client.gen/classes/Binding)

Load a Binding from its ID.

#### Parameters

##### id

[`BindingID`](/reference/typescript/api/client.gen/type-aliases/BindingID)

#### Returns

[`Binding`](/reference/typescript/api/client.gen/classes/Binding)

---

### loadCacheVolumeFromID()

> **loadCacheVolumeFromID**(`id`): [`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

Load a CacheVolume from its ID.

#### Parameters

##### id

[`CacheVolumeID`](/reference/typescript/api/client.gen/type-aliases/CacheVolumeID)

#### Returns

[`CacheVolume`](/reference/typescript/api/client.gen/classes/CacheVolume)

---

### loadChangesetFromID()

> **loadChangesetFromID**(`id`): [`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

Load a Changeset from its ID.

#### Parameters

##### id

[`ChangesetID`](/reference/typescript/api/client.gen/type-aliases/ChangesetID)

#### Returns

[`Changeset`](/reference/typescript/api/client.gen/classes/Changeset)

---

### loadCheckFromID()

> **loadCheckFromID**(`id`): [`Check`](/reference/typescript/api/client.gen/classes/Check)

Load a Check from its ID.

#### Parameters

##### id

[`CheckID`](/reference/typescript/api/client.gen/type-aliases/CheckID)

#### Returns

[`Check`](/reference/typescript/api/client.gen/classes/Check)

---

### loadCheckGroupFromID()

> **loadCheckGroupFromID**(`id`): [`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

Load a CheckGroup from its ID.

#### Parameters

##### id

[`CheckGroupID`](/reference/typescript/api/client.gen/type-aliases/CheckGroupID)

#### Returns

[`CheckGroup`](/reference/typescript/api/client.gen/classes/CheckGroup)

---

### loadCloudFromID()

> **loadCloudFromID**(`id`): [`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

Load a Cloud from its ID.

#### Parameters

##### id

[`CloudID`](/reference/typescript/api/client.gen/type-aliases/CloudID)

#### Returns

[`Cloud`](/reference/typescript/api/client.gen/classes/Cloud)

---

### loadContainerFromID()

> **loadContainerFromID**(`id`): [`Container`](/reference/typescript/api/client.gen/classes/Container)

Load a Container from its ID.

#### Parameters

##### id

[`ContainerID`](/reference/typescript/api/client.gen/type-aliases/ContainerID)

#### Returns

[`Container`](/reference/typescript/api/client.gen/classes/Container)

---

### loadCurrentModuleFromID()

> **loadCurrentModuleFromID**(`id`): [`CurrentModule`](/reference/typescript/api/client.gen/classes/CurrentModule)

Load a CurrentModule from its ID.

#### Parameters

##### id

[`CurrentModuleID`](/reference/typescript/api/client.gen/type-aliases/CurrentModuleID)

#### Returns

[`CurrentModule`](/reference/typescript/api/client.gen/classes/CurrentModule)

---

### loadDirectoryFromID()

> **loadDirectoryFromID**(`id`): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

Load a Directory from its ID.

#### Parameters

##### id

[`DirectoryID`](/reference/typescript/api/client.gen/type-aliases/DirectoryID)

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### loadEngineCacheEntryFromID()

> **loadEngineCacheEntryFromID**(`id`): [`EngineCacheEntry`](/reference/typescript/api/client.gen/classes/EngineCacheEntry)

Load a EngineCacheEntry from its ID.

#### Parameters

##### id

[`EngineCacheEntryID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntryID)

#### Returns

[`EngineCacheEntry`](/reference/typescript/api/client.gen/classes/EngineCacheEntry)

---

### loadEngineCacheEntrySetFromID()

> **loadEngineCacheEntrySetFromID**(`id`): [`EngineCacheEntrySet`](/reference/typescript/api/client.gen/classes/EngineCacheEntrySet)

Load a EngineCacheEntrySet from its ID.

#### Parameters

##### id

[`EngineCacheEntrySetID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheEntrySetID)

#### Returns

[`EngineCacheEntrySet`](/reference/typescript/api/client.gen/classes/EngineCacheEntrySet)

---

### loadEngineCacheFromID()

> **loadEngineCacheFromID**(`id`): [`EngineCache`](/reference/typescript/api/client.gen/classes/EngineCache)

Load a EngineCache from its ID.

#### Parameters

##### id

[`EngineCacheID`](/reference/typescript/api/client.gen/type-aliases/EngineCacheID)

#### Returns

[`EngineCache`](/reference/typescript/api/client.gen/classes/EngineCache)

---

### loadEngineFromID()

> **loadEngineFromID**(`id`): [`Engine`](/reference/typescript/api/client.gen/classes/Engine)

Load a Engine from its ID.

#### Parameters

##### id

[`EngineID`](/reference/typescript/api/client.gen/type-aliases/EngineID)

#### Returns

[`Engine`](/reference/typescript/api/client.gen/classes/Engine)

---

### loadEnumTypeDefFromID()

> **loadEnumTypeDefFromID**(`id`): [`EnumTypeDef`](/reference/typescript/api/client.gen/classes/EnumTypeDef)

Load a EnumTypeDef from its ID.

#### Parameters

##### id

[`EnumTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumTypeDefID)

#### Returns

[`EnumTypeDef`](/reference/typescript/api/client.gen/classes/EnumTypeDef)

---

### loadEnumValueTypeDefFromID()

> **loadEnumValueTypeDefFromID**(`id`): [`EnumValueTypeDef`](/reference/typescript/api/client.gen/classes/EnumValueTypeDef)

Load a EnumValueTypeDef from its ID.

#### Parameters

##### id

[`EnumValueTypeDefID`](/reference/typescript/api/client.gen/type-aliases/EnumValueTypeDefID)

#### Returns

[`EnumValueTypeDef`](/reference/typescript/api/client.gen/classes/EnumValueTypeDef)

---

### loadEnvFileFromID()

> **loadEnvFileFromID**(`id`): [`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

Load a EnvFile from its ID.

#### Parameters

##### id

[`EnvFileID`](/reference/typescript/api/client.gen/type-aliases/EnvFileID)

#### Returns

[`EnvFile`](/reference/typescript/api/client.gen/classes/EnvFile)

---

### loadEnvFromID()

> **loadEnvFromID**(`id`): [`Env`](/reference/typescript/api/client.gen/classes/Env)

Load a Env from its ID.

#### Parameters

##### id

[`EnvID`](/reference/typescript/api/client.gen/type-aliases/EnvID)

#### Returns

[`Env`](/reference/typescript/api/client.gen/classes/Env)

---

### loadEnvVariableFromID()

> **loadEnvVariableFromID**(`id`): [`EnvVariable`](/reference/typescript/api/client.gen/classes/EnvVariable)

Load a EnvVariable from its ID.

#### Parameters

##### id

[`EnvVariableID`](/reference/typescript/api/client.gen/type-aliases/EnvVariableID)

#### Returns

[`EnvVariable`](/reference/typescript/api/client.gen/classes/EnvVariable)

---

### loadErrorFromID()

> **loadErrorFromID**(`id`): [`Error`](/reference/typescript/api/client.gen/classes/Error)

Load a Error from its ID.

#### Parameters

##### id

[`ErrorID`](/reference/typescript/api/client.gen/type-aliases/ErrorID)

#### Returns

[`Error`](/reference/typescript/api/client.gen/classes/Error)

---

### loadErrorValueFromID()

> **loadErrorValueFromID**(`id`): [`ErrorValue`](/reference/typescript/api/client.gen/classes/ErrorValue)

Load a ErrorValue from its ID.

#### Parameters

##### id

[`ErrorValueID`](/reference/typescript/api/client.gen/type-aliases/ErrorValueID)

#### Returns

[`ErrorValue`](/reference/typescript/api/client.gen/classes/ErrorValue)

---

### loadFieldTypeDefFromID()

> **loadFieldTypeDefFromID**(`id`): [`FieldTypeDef`](/reference/typescript/api/client.gen/classes/FieldTypeDef)

Load a FieldTypeDef from its ID.

#### Parameters

##### id

[`FieldTypeDefID`](/reference/typescript/api/client.gen/type-aliases/FieldTypeDefID)

#### Returns

[`FieldTypeDef`](/reference/typescript/api/client.gen/classes/FieldTypeDef)

---

### loadFileFromID()

> **loadFileFromID**(`id`): [`File`](/reference/typescript/api/client.gen/classes/File)

Load a File from its ID.

#### Parameters

##### id

[`FileID`](/reference/typescript/api/client.gen/type-aliases/FileID)

#### Returns

[`File`](/reference/typescript/api/client.gen/classes/File)

---

### loadFunctionArgFromID()

> **loadFunctionArgFromID**(`id`): [`FunctionArg`](/reference/typescript/api/client.gen/classes/FunctionArg)

Load a FunctionArg from its ID.

#### Parameters

##### id

[`FunctionArgID`](/reference/typescript/api/client.gen/type-aliases/FunctionArgID)

#### Returns

[`FunctionArg`](/reference/typescript/api/client.gen/classes/FunctionArg)

---

### loadFunctionCallArgValueFromID()

> **loadFunctionCallArgValueFromID**(`id`): [`FunctionCallArgValue`](/reference/typescript/api/client.gen/classes/FunctionCallArgValue)

Load a FunctionCallArgValue from its ID.

#### Parameters

##### id

[`FunctionCallArgValueID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallArgValueID)

#### Returns

[`FunctionCallArgValue`](/reference/typescript/api/client.gen/classes/FunctionCallArgValue)

---

### loadFunctionCallFromID()

> **loadFunctionCallFromID**(`id`): [`FunctionCall`](/reference/typescript/api/client.gen/classes/FunctionCall)

Load a FunctionCall from its ID.

#### Parameters

##### id

[`FunctionCallID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallID)

#### Returns

[`FunctionCall`](/reference/typescript/api/client.gen/classes/FunctionCall)

---

### loadFunctionFromID()

> **loadFunctionFromID**(`id`): [`Function_`](/reference/typescript/api/client.gen/classes/Function)

Load a Function from its ID.

#### Parameters

##### id

[`FunctionID`](/reference/typescript/api/client.gen/type-aliases/FunctionID)

#### Returns

[`Function_`](/reference/typescript/api/client.gen/classes/Function)

---

### loadGeneratedCodeFromID()

> **loadGeneratedCodeFromID**(`id`): [`GeneratedCode`](/reference/typescript/api/client.gen/classes/GeneratedCode)

Load a GeneratedCode from its ID.

#### Parameters

##### id

[`GeneratedCodeID`](/reference/typescript/api/client.gen/type-aliases/GeneratedCodeID)

#### Returns

[`GeneratedCode`](/reference/typescript/api/client.gen/classes/GeneratedCode)

---

### loadGitRefFromID()

> **loadGitRefFromID**(`id`): [`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

Load a GitRef from its ID.

#### Parameters

##### id

[`GitRefID`](/reference/typescript/api/client.gen/type-aliases/GitRefID)

#### Returns

[`GitRef`](/reference/typescript/api/client.gen/classes/GitRef)

---

### loadGitRepositoryFromID()

> **loadGitRepositoryFromID**(`id`): [`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

Load a GitRepository from its ID.

#### Parameters

##### id

[`GitRepositoryID`](/reference/typescript/api/client.gen/type-aliases/GitRepositoryID)

#### Returns

[`GitRepository`](/reference/typescript/api/client.gen/classes/GitRepository)

---

### loadHostFromID()

> **loadHostFromID**(`id`): [`Host`](/reference/typescript/api/client.gen/classes/Host)

Load a Host from its ID.

#### Parameters

##### id

[`HostID`](/reference/typescript/api/client.gen/type-aliases/HostID)

#### Returns

[`Host`](/reference/typescript/api/client.gen/classes/Host)

---

### loadInputTypeDefFromID()

> **loadInputTypeDefFromID**(`id`): [`InputTypeDef`](/reference/typescript/api/client.gen/classes/InputTypeDef)

Load a InputTypeDef from its ID.

#### Parameters

##### id

[`InputTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InputTypeDefID)

#### Returns

[`InputTypeDef`](/reference/typescript/api/client.gen/classes/InputTypeDef)

---

### loadInterfaceTypeDefFromID()

> **loadInterfaceTypeDefFromID**(`id`): [`InterfaceTypeDef`](/reference/typescript/api/client.gen/classes/InterfaceTypeDef)

Load a InterfaceTypeDef from its ID.

#### Parameters

##### id

[`InterfaceTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InterfaceTypeDefID)

#### Returns

[`InterfaceTypeDef`](/reference/typescript/api/client.gen/classes/InterfaceTypeDef)

---

### loadJSONValueFromID()

> **loadJSONValueFromID**(`id`): [`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

Load a JSONValue from its ID.

#### Parameters

##### id

[`JSONValueID`](/reference/typescript/api/client.gen/type-aliases/JSONValueID)

#### Returns

[`JSONValue`](/reference/typescript/api/client.gen/classes/JSONValue)

---

### loadLabelFromID()

> **loadLabelFromID**(`id`): [`Label`](/reference/typescript/api/client.gen/classes/Label)

Load a Label from its ID.

#### Parameters

##### id

[`LabelID`](/reference/typescript/api/client.gen/type-aliases/LabelID)

#### Returns

[`Label`](/reference/typescript/api/client.gen/classes/Label)

---

### loadListTypeDefFromID()

> **loadListTypeDefFromID**(`id`): [`ListTypeDef`](/reference/typescript/api/client.gen/classes/ListTypeDef)

Load a ListTypeDef from its ID.

#### Parameters

##### id

[`ListTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ListTypeDefID)

#### Returns

[`ListTypeDef`](/reference/typescript/api/client.gen/classes/ListTypeDef)

---

### loadLLMFromID()

> **loadLLMFromID**(`id`): [`LLM`](/reference/typescript/api/client.gen/classes/LLM)

Load a LLM from its ID.

#### Parameters

##### id

[`LLMID`](/reference/typescript/api/client.gen/type-aliases/LLMID)

#### Returns

[`LLM`](/reference/typescript/api/client.gen/classes/LLM)

---

### loadLLMTokenUsageFromID()

> **loadLLMTokenUsageFromID**(`id`): [`LLMTokenUsage`](/reference/typescript/api/client.gen/classes/LLMTokenUsage)

Load a LLMTokenUsage from its ID.

#### Parameters

##### id

[`LLMTokenUsageID`](/reference/typescript/api/client.gen/type-aliases/LLMTokenUsageID)

#### Returns

[`LLMTokenUsage`](/reference/typescript/api/client.gen/classes/LLMTokenUsage)

---

### loadModuleConfigClientFromID()

> **loadModuleConfigClientFromID**(`id`): [`ModuleConfigClient`](/reference/typescript/api/client.gen/classes/ModuleConfigClient)

Load a ModuleConfigClient from its ID.

#### Parameters

##### id

[`ModuleConfigClientID`](/reference/typescript/api/client.gen/type-aliases/ModuleConfigClientID)

#### Returns

[`ModuleConfigClient`](/reference/typescript/api/client.gen/classes/ModuleConfigClient)

---

### loadModuleFromID()

> **loadModuleFromID**(`id`): [`Module_`](/reference/typescript/api/client.gen/classes/Module)

Load a Module from its ID.

#### Parameters

##### id

[`ModuleID`](/reference/typescript/api/client.gen/type-aliases/ModuleID)

#### Returns

[`Module_`](/reference/typescript/api/client.gen/classes/Module)

---

### loadModuleSourceFromID()

> **loadModuleSourceFromID**(`id`): [`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

Load a ModuleSource from its ID.

#### Parameters

##### id

[`ModuleSourceID`](/reference/typescript/api/client.gen/type-aliases/ModuleSourceID)

#### Returns

[`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

---

### loadObjectTypeDefFromID()

> **loadObjectTypeDefFromID**(`id`): [`ObjectTypeDef`](/reference/typescript/api/client.gen/classes/ObjectTypeDef)

Load a ObjectTypeDef from its ID.

#### Parameters

##### id

[`ObjectTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ObjectTypeDefID)

#### Returns

[`ObjectTypeDef`](/reference/typescript/api/client.gen/classes/ObjectTypeDef)

---

### loadPortFromID()

> **loadPortFromID**(`id`): [`Port`](/reference/typescript/api/client.gen/classes/Port)

Load a Port from its ID.

#### Parameters

##### id

[`PortID`](/reference/typescript/api/client.gen/type-aliases/PortID)

#### Returns

[`Port`](/reference/typescript/api/client.gen/classes/Port)

---

### loadScalarTypeDefFromID()

> **loadScalarTypeDefFromID**(`id`): [`ScalarTypeDef`](/reference/typescript/api/client.gen/classes/ScalarTypeDef)

Load a ScalarTypeDef from its ID.

#### Parameters

##### id

[`ScalarTypeDefID`](/reference/typescript/api/client.gen/type-aliases/ScalarTypeDefID)

#### Returns

[`ScalarTypeDef`](/reference/typescript/api/client.gen/classes/ScalarTypeDef)

---

### loadSDKConfigFromID()

> **loadSDKConfigFromID**(`id`): [`SDKConfig`](/reference/typescript/api/client.gen/classes/SDKConfig)

Load a SDKConfig from its ID.

#### Parameters

##### id

[`SDKConfigID`](/reference/typescript/api/client.gen/type-aliases/SDKConfigID)

#### Returns

[`SDKConfig`](/reference/typescript/api/client.gen/classes/SDKConfig)

---

### loadSearchResultFromID()

> **loadSearchResultFromID**(`id`): [`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)

Load a SearchResult from its ID.

#### Parameters

##### id

[`SearchResultID`](/reference/typescript/api/client.gen/type-aliases/SearchResultID)

#### Returns

[`SearchResult`](/reference/typescript/api/client.gen/classes/SearchResult)

---

### loadSearchSubmatchFromID()

> **loadSearchSubmatchFromID**(`id`): [`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)

Load a SearchSubmatch from its ID.

#### Parameters

##### id

[`SearchSubmatchID`](/reference/typescript/api/client.gen/type-aliases/SearchSubmatchID)

#### Returns

[`SearchSubmatch`](/reference/typescript/api/client.gen/classes/SearchSubmatch)

---

### loadSecretFromID()

> **loadSecretFromID**(`id`): [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Load a Secret from its ID.

#### Parameters

##### id

[`SecretID`](/reference/typescript/api/client.gen/type-aliases/SecretID)

#### Returns

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

---

### loadServiceFromID()

> **loadServiceFromID**(`id`): [`Service`](/reference/typescript/api/client.gen/classes/Service)

Load a Service from its ID.

#### Parameters

##### id

[`ServiceID`](/reference/typescript/api/client.gen/type-aliases/ServiceID)

#### Returns

[`Service`](/reference/typescript/api/client.gen/classes/Service)

---

### loadSocketFromID()

> **loadSocketFromID**(`id`): [`Socket`](/reference/typescript/api/client.gen/classes/Socket)

Load a Socket from its ID.

#### Parameters

##### id

[`SocketID`](/reference/typescript/api/client.gen/type-aliases/SocketID)

#### Returns

[`Socket`](/reference/typescript/api/client.gen/classes/Socket)

---

### loadSourceMapFromID()

> **loadSourceMapFromID**(`id`): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

Load a SourceMap from its ID.

#### Parameters

##### id

[`SourceMapID`](/reference/typescript/api/client.gen/type-aliases/SourceMapID)

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### loadTerminalFromID()

> **loadTerminalFromID**(`id`): [`Terminal`](/reference/typescript/api/client.gen/classes/Terminal)

Load a Terminal from its ID.

#### Parameters

##### id

[`TerminalID`](/reference/typescript/api/client.gen/type-aliases/TerminalID)

#### Returns

[`Terminal`](/reference/typescript/api/client.gen/classes/Terminal)

---

### loadTypeDefFromID()

> **loadTypeDefFromID**(`id`): [`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

Load a TypeDef from its ID.

#### Parameters

##### id

[`TypeDefID`](/reference/typescript/api/client.gen/type-aliases/TypeDefID)

#### Returns

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

---

### module\_()

> **module\_**(): [`Module_`](/reference/typescript/api/client.gen/classes/Module)

Create a new module.

#### Returns

[`Module_`](/reference/typescript/api/client.gen/classes/Module)

---

### moduleSource()

> **moduleSource**(`refString`, `opts?`): [`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

Create a new module source instance from a source ref string

#### Parameters

##### refString

`string`

The string ref representation of the module source

##### opts?

[`ClientModuleSourceOpts`](/reference/typescript/api/client.gen/type-aliases/ClientModuleSourceOpts)

#### Returns

[`ModuleSource`](/reference/typescript/api/client.gen/classes/ModuleSource)

---

### secret()

> **secret**(`uri`, `opts?`): [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Creates a new secret.

#### Parameters

##### uri

`string`

The URI of the secret store

##### opts?

[`ClientSecretOpts`](/reference/typescript/api/client.gen/type-aliases/ClientSecretOpts)

#### Returns

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

---

### setSecret()

> **setSecret**(`name`, `plaintext`): [`Secret`](/reference/typescript/api/client.gen/classes/Secret)

Sets a secret given a user defined name to its plaintext and returns the secret.

The plaintext value is limited to a size of 128000 bytes.

#### Parameters

##### name

`string`

The user defined name for this secret

##### plaintext

`string`

The plaintext of the secret

#### Returns

[`Secret`](/reference/typescript/api/client.gen/classes/Secret)

---

### sourceMap()

> **sourceMap**(`filename`, `line`, `column`): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

Creates source map metadata.

#### Parameters

##### filename

`string`

The filename from the module source.

##### line

`number`

The line number within the filename.

##### column

`number`

The column number within the line.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### typeDef()

> **typeDef**(): [`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

Create a new TypeDef.

#### Returns

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

---

### version()

> **version**(): `Promise`<`string`\>

Get the current Dagger Engine version.

#### Returns

`Promise`<`string`\>
