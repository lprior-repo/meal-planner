---
doc_id: ref/errors/dockerimagerefvalidationerror
chunk_id: ref/errors/dockerimagerefvalidationerror#chunk-3
heading_path: ["dockerimagerefvalidationerror", "Properties"]
chunk_type: prose
tokens: 120
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

> **code**: `"D107"` = `ERROR_CODES.DockerImageRefValidationError`

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

> **name**: `"DockerImageRefValidationError"` = `ERROR_NAMES.DockerImageRefValidationError`

The name of the dagger error.

#### Overrides

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`name`](/reference/typescript/common/errors/classes/DaggerSDKError#name)

---

### ref

> **ref**: `string`

The docker image reference, which caused the error.

---

### stack?

> `optional` **stack**: `string`

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`stack`](/reference/typescript/common/errors/classes/DaggerSDKError#stack)
