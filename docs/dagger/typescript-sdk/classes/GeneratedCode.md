# Class: GeneratedCode

The result of running an SDK's codegen.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new GeneratedCode**(`ctx?`, `_id?`): `GeneratedCode`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`GeneratedCodeID`](/reference/typescript/api/client.gen/type-aliases/GeneratedCodeID)

#### Returns

`GeneratedCode`

#### Overrides

`BaseClient.constructor`

## Methods

### code()

> **code**(): [`Directory`](/reference/typescript/api/client.gen/classes/Directory)

The directory containing the generated code.

#### Returns

[`Directory`](/reference/typescript/api/client.gen/classes/Directory)

---

### id()

> **id**(): `Promise`<[`GeneratedCodeID`](/reference/typescript/api/client.gen/type-aliases/GeneratedCodeID)\>

A unique identifier for this GeneratedCode.

#### Returns

`Promise`<[`GeneratedCodeID`](/reference/typescript/api/client.gen/type-aliases/GeneratedCodeID)\>

---

### vcsGeneratedPaths()

> **vcsGeneratedPaths**(): `Promise`<`string`\[\]>

List of paths to mark generated in version control (i.e. .gitattributes).

#### Returns

`Promise`<`string`\[\]>

---

### vcsIgnoredPaths()

> **vcsIgnoredPaths**(): `Promise`<`string`\[\]>

List of paths to ignore in version control (i.e. .gitignore).

#### Returns

`Promise`<`string`\[\]>

---

### with()

> **with**(`arg`): `GeneratedCode`

Call the provided function with current GeneratedCode.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

##### arg

(`param`) => `GeneratedCode`

#### Returns

`GeneratedCode`

---

### withVCSGeneratedPaths()

> **withVCSGeneratedPaths**(`paths`): `GeneratedCode`

Set the list of paths to mark generated in version control.

#### Parameters

##### paths

`string`\[\]

#### Returns

`GeneratedCode`

---

### withVCSIgnoredPaths()

> **withVCSIgnoredPaths**(`paths`): `GeneratedCode`

Set the list of paths to ignore in version control.

#### Parameters

##### paths

`string`\[\]

#### Returns

`GeneratedCode`
