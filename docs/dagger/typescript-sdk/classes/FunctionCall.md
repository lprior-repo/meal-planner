# Class: FunctionCall

An active function call.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new FunctionCall**(`ctx?`, `_id?`, `_name?`, `_parent?`, `_parentName?`, `_returnError?`, `_returnValue?`): `FunctionCall`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`FunctionCallID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallID)

##### \_name?

`string`

##### \_parent?

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

##### \_parentName?

`string`

##### \_returnError?

[`Void`](/reference/typescript/api/client.gen/type-aliases/Void)

##### \_returnValue?

[`Void`](/reference/typescript/api/client.gen/type-aliases/Void)

#### Returns

`FunctionCall`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`FunctionCallID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallID)\>

A unique identifier for this FunctionCall.

#### Returns

`Promise`<[`FunctionCallID`](/reference/typescript/api/client.gen/type-aliases/FunctionCallID)\>

---

### inputArgs()

> **inputArgs**(): `Promise`<[`FunctionCallArgValue`](/reference/typescript/api/client.gen/classes/FunctionCallArgValue)\[\]>

The argument values the function is being invoked with.

#### Returns

`Promise`<[`FunctionCallArgValue`](/reference/typescript/api/client.gen/classes/FunctionCallArgValue)\[\]>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the function being called.

#### Returns

`Promise`<`string`\>

---

### parent()

> **parent**(): `Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

The value of the parent object of the function being called. If the function is top-level to the module, this is always an empty object.

#### Returns

`Promise`<[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)\>

---

### parentName()

> **parentName**(): `Promise`<`string`\>

The name of the parent object of the function being called. If the function is top-level to the module, this is the name of the module.

#### Returns

`Promise`<`string`\>

---

### returnError()

> **returnError**(`error`): `Promise`<`void`\>

Return an error from the function.

#### Parameters

##### error

[`Error`](/reference/typescript/api/client.gen/classes/Error)

The error to return.

#### Returns

`Promise`<`void`\>

---

### returnValue()

> **returnValue**(`value`): `Promise`<`void`\>

Set the return value of the function call to the provided value.

#### Parameters

##### value

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

JSON serialization of the return value.

#### Returns

`Promise`<`void`\>
