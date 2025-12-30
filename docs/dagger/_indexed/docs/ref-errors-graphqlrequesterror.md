---
id: ref/errors/graphqlrequesterror
title: "Class: GraphQLRequestError"
category: ref
tags: ["graphql", "ref", "trace", "typescript", "sdk"]
---

# Class: GraphQLRequestError

> **Context**: This error originates from the dagger engine. It means that some error was thrown and sent back via GraphQL.


This error originates from the dagger engine. It means that some error was thrown and sent back via GraphQL.

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

> **code**: `"D100"` = `ERROR_CODES.GraphQLRequestError`

The dagger specific error code. Use this to identify dagger errors programmatically.

#### Overrides

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`code`](/reference/typescript/common/errors/classes/DaggerSDKError#code)

---

### extensions?

> `optional` **extensions**: `any`

The GraphQL error extentions.

---

### message

> **message**: `string`

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`message`](/reference/typescript/common/errors/classes/DaggerSDKError#message)

---

### name

> **name**: `"GraphQLRequestError"` = `ERROR_NAMES.GraphQLRequestError`

The name of the dagger error.

#### Overrides

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`name`](/reference/typescript/common/errors/classes/DaggerSDKError#name)

---

### requestContext

> **requestContext**: `ClientError`

The query and variables, which caused the error.

---

### response

> **response**: `ClientError`

the GraphQL response containing the error.

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
