# Class: FunctionCallArgValue

A value passed as a named argument to a function call.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new FunctionCallArgValue**(`ctx?`, `_id?`, `_name?`, `_value?`): `FunctionCallArgValue`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`FunctionCallArgValueID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallArgValueID)

##### \_name?

`string`

##### \_value?

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

#### Returns

`FunctionCallArgValue`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`FunctionCallArgValueID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallArgValueID)\>

A unique identifier for this FunctionCallArgValue.

#### Returns

`Promise`<[`FunctionCallArgValueID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallArgValueID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the argument.

#### Returns

`Promise`<`string`\>

---

### value()

> **value**(): `Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

The value of the argument represented as a JSON serialized string.

#### Returns

`Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>
