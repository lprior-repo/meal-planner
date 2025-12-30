# Abstract Class: DaggerSDKError

The base error. Every other error inherits this error.

## Extends

- `Error`

## Extended by

- [`UnknownDaggerError`](/reference/typescript/common/errors/classes/UnknownDaggerError)
- [`DockerImageRefValidationError`](/reference/typescript/common/errors/classes/DockerImageRefValidationError)
- [`EngineSessionConnectParamsParseError`](/reference/typescript/common/errors/classes/EngineSessionConnectParamsParseError)
- [`ExecError`](/reference/typescript/common/errors/classes/ExecError)
- [`GraphQLRequestError`](/reference/typescript/common/errors/classes/GraphQLRequestError)
- [`InitEngineSessionBinaryError`](/reference/typescript/common/errors/classes/InitEngineSessionBinaryError)
- [`TooManyNestedObjectsError`](/reference/typescript/common/errors/classes/TooManyNestedObjectsError)
- [`EngineSessionError`](/reference/typescript/common/errors/classes/EngineSessionError)
- [`EngineSessionConnectionTimeoutError`](/reference/typescript/common/errors/classes/EngineSessionConnectionTimeoutError)
- [`NotAwaitedRequestError`](/reference/typescript/common/errors/classes/NotAwaitedRequestError)
- [`FunctionNotFound`](/reference/typescript/common/errors/classes/FunctionNotFound)
- [`IntrospectionError`](/reference/typescript/common/errors/classes/IntrospectionError)

## Properties

### cause?

> `optional` **cause**: `Error`

The original error, which caused the DaggerSDKError.

#### Overrides

`Error.cause`

---

### code

> `abstract` `readonly` **code**: `ErrorCodes`

The dagger specific error code. Use this to identify dagger errors programmatically.

---

### message

> **message**: `string`

#### Inherited from

`Error.message`

---

### name

> `abstract` `readonly` **name**: `"GraphQLRequestError"` | `"UnknownDaggerError"` | `"TooManyNestedObjectsError"` | `"EngineSessionConnectParamsParseError"` | `"EngineSessionConnectionTimeoutError"` | `"EngineSessionError"` | `"InitEngineSessionBinaryError"` | `"DockerImageRefValidationError"` | `"NotAwaitedRequestError"` | `"ExecError"` | `"IntrospectionError"`

The name of the dagger error.

#### Overrides

`Error.name`

---

### stack?

> `optional` **stack**: `string`

#### Inherited from

`Error.stack`

## Methods

### printStackTrace()

> **printStackTrace**(): `void`

Pretty prints the error

#### Returns

`void`
