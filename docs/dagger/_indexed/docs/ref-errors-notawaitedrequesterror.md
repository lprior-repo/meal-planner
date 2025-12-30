---
id: ref/errors/notawaitedrequesterror
title: "Class: NotAwaitedRequestError"
category: ref
tags: ["ref", "trace", "typescript", "ai", "sdk"]
---

# Class: NotAwaitedRequestError

> **Context**: This error is thrown when the compute function isn't awaited.


This error is thrown when the compute function isn't awaited.

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

> **code**: `"D108"` = `ERROR_CODES.NotAwaitedRequestError`

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

> **name**: `"NotAwaitedRequestError"` = `ERROR_NAMES.NotAwaitedRequestError`

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
