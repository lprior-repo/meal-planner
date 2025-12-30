# Class: InputTypeDef

A graphql input type, which is essentially just a group of named args. This is currently only used to represent pre-existing usage of graphql input types in the core API. It is not used by user modules and shouldn't ever be as user module accept input objects via their id rather than graphql input types.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new InputTypeDef**(`ctx?`, `_id?`, `_name?`): `InputTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`InputTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InputTypeDefID)

##### \_name?

`string`

#### Returns

`InputTypeDef`

#### Overrides

`BaseClient.constructor`

## Methods

### fields()

> **fields**(): `Promise`<[`FieldTypeDef`](/reference/typescript/api/client.gen/classes/FieldTypeDef)\[\]>

Static fields defined on this input object, if any.

#### Returns

`Promise`<[`FieldTypeDef`](/reference/typescript/api/client.gen/classes/FieldTypeDef)\[\]>

---

### id()

> **id**(): `Promise`<[`InputTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InputTypeDefID)\>

A unique identifier for this InputTypeDef.

#### Returns

`Promise`<[`InputTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InputTypeDefID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the input object.

#### Returns

`Promise`<`string`\>
