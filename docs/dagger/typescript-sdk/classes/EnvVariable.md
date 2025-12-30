# Class: EnvVariable

An environment variable name and value.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new EnvVariable**(`ctx?`, `_id?`, `_name?`, `_value?`): `EnvVariable`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`EnvVariableID`](/reference/typescript/api/client.gen/type-aliases/EnvVariableID)

##### \_name?

`string`

##### \_value?

`string`

#### Returns

`EnvVariable`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`EnvVariableID`](/reference/typescript/api/client.gen/type-aliases/EnvVariableID)\>

A unique identifier for this EnvVariable.

#### Returns

`Promise`<[`EnvVariableID`](/reference/typescript/api/client.gen/type-aliases/EnvVariableID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The environment variable name.

#### Returns

`Promise`<`string`\>

---

### value()

> **value**(): `Promise`<`string`\>

The environment variable value.

#### Returns

`Promise`<`string`\>
