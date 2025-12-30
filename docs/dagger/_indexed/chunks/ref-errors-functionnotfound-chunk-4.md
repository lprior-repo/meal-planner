---
doc_id: ref/errors/functionnotfound
chunk_id: ref/errors/functionnotfound#chunk-4
heading_path: ["functionnotfound", "Properties"]
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
