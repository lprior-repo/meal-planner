---
id: ref/errors/initenginesessionbinaryerror
title: "Class: InitEngineSessionBinaryError"
category: ref
tags: ["ref", "type", "trace", "typescript", "sdk"]
---

# Class: InitEngineSessionBinaryError

> **Context**: This error is thrown if the dagger binary cannot be copied from the dagger docker image and copied to the local host.


This error is thrown if the dagger binary cannot be copied from the dagger docker image and copied to the local host.

## Extends

- [`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError)

## Properties

### cause?

> `optional` **cause**: `Error`

The original error, which caused the DaggerSDKError.

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`cause`](/reference/typescript/common/errors/classes/DaggerSDKError#cause)

---

### code

> **code**: `"D106"` = `ERROR_CODES.InitEngineSessionBinaryError`

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

> **name**: `"InitEngineSessionBinaryError"` = `ERROR_NAMES.InitEngineSessionBinaryError`

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
