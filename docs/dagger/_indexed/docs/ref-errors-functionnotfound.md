---
id: ref/errors/functionnotfound
title: "Class: FunctionNotFound"
category: ref
tags: ["ref", "trace", "typescript", "function", "sdk"]
---

# Class: FunctionNotFound

> **Context**: The base error. Every other error inherits this error.


The base error. Every other error inherits this error.

## Extends

- [`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError)

## Constructors

### Constructor

> **new FunctionNotFound**(`message`, `options?`): `FunctionNotFound`

#### Parameters

#### message

`string`

#### options?

`DaggerSDKErrorOptions`

#### Returns

`FunctionNotFound`

#### Overrides

`DaggerSDKError.constructor`

## Properties

### cause?

> `optional` **cause**: `Error`

The original error, which caused the DaggerSDKError.

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`cause`](/reference/typescript/common/errors/classes/DaggerSDKError#cause)

---

### code

> **code**: `"D109"` = `ERROR_CODES.ExecError`

The dagger specific error code. Use this to identify dagger errors programmatically.

#### Overrides

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`code`](/reference/typescript/common/errors/classes/DaggerSDKError#code)

---

### message

> **message**: `string`

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`message`](/reference/typescript/common/errors/classes/DaggerSDKError#message)

---

### name

> **name**: `"ExecError"` = `ERROR_NAMES.ExecError`

The name of the dagger error.

#### Overrides

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`name`](/reference/typescript/common/errors/classes/DaggerSDKError#name)

---

### stack?

> `optional` **stack**: `string`

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`stack`](/reference/typescript/common/errors/classes/DaggerSDKError#stack)

## Methods

### printStackTrace()

> **printStackTrace**(): `void`

Pretty prints the error

#### Returns

`void`

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`printStackTrace`](/reference/typescript/common/errors/classes/DaggerSDKError#printstacktrace)

## See Also

- [Documentation Overview](./COMPASS.md)
