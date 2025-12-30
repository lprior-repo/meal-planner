# Class: Error

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Error**(`ctx?`, `_id?`, `_message?`): `Error`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`ErrorID`](/reference/typescript/api/client.gen/type-aliases/ErrorID)

##### \_message?

`string`

#### Returns

`Error`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`ErrorID`](/reference/typescript/api/client.gen/type-aliases/ErrorID)\>

A unique identifier for this Error.

#### Returns

`Promise`<[`ErrorID`](/reference/typescript/api/client.gen/type-aliases/ErrorID)\>

---

### message()

> **message**(): `Promise`<`string`\>

A description of the error.

#### Returns

`Promise`<`string`\>

---

### values()

> **values**(): `Promise`<[`ErrorValue`](/reference/typescript/api/client.gen/classes/ErrorValue)\[\]>

The extensions of the error.

#### Returns

`Promise`<[`ErrorValue`](/reference/typescript/api/client.gen/classes/ErrorValue)\[\]>

---

### with()

> **with**(`arg`): `Error`

Call the provided function with current Error.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

##### arg

(`param`) => `Error`

#### Returns

`Error`

---

### withValue()

> **withValue**(`name`, `value`): `Error`

Add a value to the error.

#### Parameters

##### name

`string`

The name of the value.

##### value

[`JSON`](/reference/typescript/api/client.gen/type-aliases/JSON)

The value to store on the error.

#### Returns

`Error`
