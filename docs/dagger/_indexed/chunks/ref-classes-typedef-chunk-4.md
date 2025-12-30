---
doc_id: ref/classes/typedef
chunk_id: ref/classes/typedef#chunk-4
heading_path: ["typedef", "Methods"]
chunk_type: prose
tokens: 920
summary: "> **asEnum**(): [`EnumTypeDef`](/reference/typescript/api/client."
---
### asEnum()

> **asEnum**(): [`EnumTypeDef`](/reference/typescript/api/client.gen/classes/EnumTypeDef)

If kind is ENUM, the enum-specific type definition. If kind is not ENUM, this will be null.

#### Returns

[`EnumTypeDef`](/reference/typescript/api/client.gen/classes/EnumTypeDef)

---

### asInput()

> **asInput**(): [`InputTypeDef`](/reference/typescript/api/client.gen/classes/InputTypeDef)

If kind is INPUT, the input-specific type definition. If kind is not INPUT, this will be null.

#### Returns

[`InputTypeDef`](/reference/typescript/api/client.gen/classes/InputTypeDef)

---

### asInterface()

> **asInterface**(): [`InterfaceTypeDef`](/reference/typescript/api/client.gen/classes/InterfaceTypeDef)

If kind is INTERFACE, the interface-specific type definition. If kind is not INTERFACE, this will be null.

#### Returns

[`InterfaceTypeDef`](/reference/typescript/api/client.gen/classes/InterfaceTypeDef)

---

### asList()

> **asList**(): [`ListTypeDef`](/reference/typescript/api/client.gen/classes/ListTypeDef)

If kind is LIST, the list-specific type definition. If kind is not LIST, this will be null.

#### Returns

[`ListTypeDef`](/reference/typescript/api/client.gen/classes/ListTypeDef)

---

### asObject()

> **asObject**(): [`ObjectTypeDef`](/reference/typescript/api/client.gen/classes/ObjectTypeDef)

If kind is OBJECT, the object-specific type definition. If kind is not OBJECT, this will be null.

#### Returns

[`ObjectTypeDef`](/reference/typescript/api/client.gen/classes/ObjectTypeDef)

---

### asScalar()

> **asScalar**(): [`ScalarTypeDef`](/reference/typescript/api/client.gen/classes/ScalarTypeDef)

If kind is SCALAR, the scalar-specific type definition. If kind is not SCALAR, this will be null.

#### Returns

[`ScalarTypeDef`](/reference/typescript/api/client.gen/classes/ScalarTypeDef)

---

### id()

> **id**(): `Promise`<[`TypeDefID`](/reference/typescript/api/client.gen/type-aliases/TypeDefID)\>

A unique identifier for this TypeDef.

#### Returns

`Promise`<[`TypeDefID`](/reference/typescript/api/client.gen/type-aliases/TypeDefID)\>

---

### kind()

> **kind**(): `Promise`<[`TypeDefKind`](/reference/typescript/api/client.gen/enumerations/TypeDefKind)\>

The kind of type this is (e.g. primitive, list, object).

#### Returns

`Promise`<[`TypeDefKind`](/reference/typescript/api/client.gen/enumerations/TypeDefKind)\>

---

### optional()

> **optional**(): `Promise`<`boolean`\>

Whether this type can be set to null. Defaults to false.

#### Returns

`Promise`<`boolean`\>

---

### with()

> **with**(`arg`): `TypeDef`

Call the provided function with current TypeDef.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `TypeDef`

#### Returns

`TypeDef`

---

### withConstructor()

> **withConstructor**(`function_`): `TypeDef`

Adds a function for constructing a new instance of an Object TypeDef, failing if the type is not an object.

#### Parameters

#### function\_

[`Function_`](/reference/typescript/api/client.gen/classes/Function)

#### Returns

`TypeDef`

---

### withEnum()

> **withEnum**(`name`, `opts?`): `TypeDef`

Returns a TypeDef of kind Enum with the provided name.

Note that an enum's values may be omitted if the intent is only to refer to an enum. This is how functions are able to return their own, or any other circular reference.

#### Parameters

#### name

`string`

The name of the enum

#### opts?

[`TypeDefWithEnumOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithEnumOpts)

#### Returns

`TypeDef`

---

### withEnumMember()

> **withEnumMember**(`name`, `opts?`): `TypeDef`

Adds a static value for an Enum TypeDef, failing if the type is not an enum.

#### Parameters

#### name

`string`

The name of the member in the enum

#### opts?

[`TypeDefWithEnumMemberOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithEnumMemberOpts)

#### Returns

`TypeDef`

---

### withEnumValue() (Deprecated)

> **withEnumValue**(`value`, `opts?`): `TypeDef`

Adds a static value for an Enum TypeDef, failing if the type is not an enum.

**Deprecated**: Use withEnumMember instead

#### Parameters

#### value

`string`

The name of the value in the enum

#### opts?

[`TypeDefWithEnumValueOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithEnumValueOpts)

#### Returns

`TypeDef`

---

### withField()

> **withField**(`name`, `typeDef`, `opts?`): `TypeDef`

Adds a static field for an Object TypeDef, failing if the type is not an object.

#### Parameters

#### name

`string`

The name of the field in the object

#### typeDef

`TypeDef`

The type of the field

#### opts?

[`TypeDefWithFieldOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithFieldOpts)

#### Returns

`TypeDef`

---

### withFunction()

> **withFunction**(`function_`): `TypeDef`

Adds a function for an Object or Interface TypeDef, failing if the type is not one of those kinds.

#### Parameters

#### function\_

[`Function_`](/reference/typescript/api/client.gen/classes/Function)

#### Returns

`TypeDef`

---

### withInterface()

> **withInterface**(`name`, `opts?`): `TypeDef`

Returns a TypeDef of kind Interface with the provided name.

#### Parameters

#### name

`string`

#### opts?

[`TypeDefWithInterfaceOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithInterfaceOpts)

#### Returns

`TypeDef`

---

### withKind()

> **withKind**(`kind`): `TypeDef`

Sets the kind of the type.

#### Parameters

#### kind

[`TypeDefKind`](/reference/typescript/api/client.gen/enumerations/TypeDefKind)

#### Returns

`TypeDef`

---

### withListOf()

> **withListOf**(`elementType`): `TypeDef`

Returns a TypeDef of kind List with the provided type for its elements.

#### Parameters

#### elementType

`TypeDef`

#### Returns

`TypeDef`

---

### withObject()

> **withObject**(`name`, `opts?`): `TypeDef`

Returns a TypeDef of kind Object with the provided name.

Note that an object's fields and functions may be omitted if the intent is only to refer to an object. This is how functions are able to return their own object, or any other circular reference.

#### Parameters

#### name

`string`

#### opts?

[`TypeDefWithObjectOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithObjectOpts)

#### Returns

`TypeDef`

---

### withOptional()

> **withOptional**(`optional`): `TypeDef`

Sets whether this type can be set to null.

#### Parameters

#### optional

`boolean`

#### Returns

`TypeDef`

---

### withScalar()

> **withScalar**(`name`, `opts?`): `TypeDef`

Returns a TypeDef of kind Scalar with the provided name.

#### Parameters

#### name

`string`

#### opts?

[`TypeDefWithScalarOpts`](/reference/typescript/api/client.gen/type-aliases/TypeDefWithScalarOpts)

#### Returns

`TypeDef`
