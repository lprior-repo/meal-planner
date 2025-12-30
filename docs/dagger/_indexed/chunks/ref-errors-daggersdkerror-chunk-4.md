---
doc_id: ref/errors/daggersdkerror
chunk_id: ref/errors/daggersdkerror#chunk-4
heading_path: ["daggersdkerror", "Properties"]
chunk_type: prose
tokens: 122
summary: "> `optional` **cause**: `Error`

The original error, which caused the DaggerSDKError."
---
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
