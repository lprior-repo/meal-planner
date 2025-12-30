---
doc_id: ref/errors/enginesessionconnectparamsparseerror
chunk_id: ref/errors/enginesessionconnectparamsparseerror#chunk-3
heading_path: ["enginesessionconnectparamsparseerror", "Properties"]
chunk_type: prose
tokens: 130
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

> **code**: `"D103"` = `ERROR_CODES.EngineSessionConnectParamsParseError`

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

> **name**: `"EngineSessionConnectParamsParseError"` = `ERROR_NAMES.EngineSessionConnectParamsParseError`

The name of the dagger error.

#### Overrides

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`name`](/reference/typescript/common/errors/classes/DaggerSDKError#name)

---

### parsedLine

> **parsedLine**: `string`

the line, which caused the error during parsing, if the error was caused because of parsing.

---

### stack?

> `optional` **stack**: `string`

#### Inherited from

[`DaggerSDKError`](/reference/typescript/common/errors/classes/DaggerSDKError).[`stack`](/reference/typescript/common/errors/classes/DaggerSDKError#stack)
