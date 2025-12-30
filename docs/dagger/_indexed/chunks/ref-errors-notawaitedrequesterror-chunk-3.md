---
doc_id: ref/errors/notawaitedrequesterror
chunk_id: ref/errors/notawaitedrequesterror#chunk-3
heading_path: ["notawaitedrequesterror", "Properties"]
chunk_type: prose
tokens: 101
summary: "> `optional` **cause**: `Error`

The original error, which caused the DaggerSDKError."
---
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
