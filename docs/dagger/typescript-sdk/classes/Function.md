# Class: Function\_

Function represents a resolver provided by a Module.

A function always evaluates against a parent object and is given a set of named arguments.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Function\_**(`ctx?`, `_id?`, `_deprecated?`, `_description?`, `_name?`): `Function_`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`FunctionID`](/reference/typescript/api/client.gen/type-aliases/FunctionID)

##### \_deprecated?

`string`

##### \_description?

`string`

##### \_name?

`string`

#### Returns

`Function_`

#### Overrides

`BaseClient.constructor`

## Methods

### args()

> **args**(): `Promise`<[`FunctionArg`](/reference/typescript/api/client.gen/classes/FunctionArg)\[\]>

Arguments accepted by the function, if any.

#### Returns

`Promise`<[`FunctionArg`](/reference/typescript/api/client.gen/classes/FunctionArg)\[\]>

---

### deprecated()

> **deprecated**(): `Promise`<`string`\>

The reason this function is deprecated, if any.

#### Returns

`Promise`<`string`\>

---

### description()

> **description**(): `Promise`<`string`\>

A doc string for the function, if any.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`FunctionID`](/reference/typescript/api/client.gen/type-aliases/FunctionID)\>

A unique identifier for this Function.

#### Returns

`Promise`<[`FunctionID`](/reference/typescript/api/client.gen/type-aliases/FunctionID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the function.

#### Returns

`Promise`<`string`\>

---

### returnType()

> **returnType**(): [`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

The type returned by the function.

#### Returns

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

---

### sourceMap()

> **sourceMap**(): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The location of this function declaration.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### with()

> **with**(`arg`): `Function_`

Call the provided function with current Function.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

##### arg

(`param`) => `Function_`

#### Returns

`Function_`

---

### withArg()

> **withArg**(`name`, `typeDef`, `opts?`): `Function_`

Returns the function with the provided argument

#### Parameters

##### name

`string`

The name of the argument

##### typeDef

[`TypeDef`](/reference/typescript/api/client.gen/classes/TypeDef)

The type of the argument

##### opts?

[`FunctionWithArgOpts`](/reference/typescript/api/client.gen/type-aliases/FunctionWithArgOpts)

#### Returns

`Function_`

---

### withCachePolicy()

> **withCachePolicy**(`policy`, `opts?`): `Function_`

Returns the function updated to use the provided cache policy.

#### Parameters

##### policy

[`FunctionCachePolicy`](/reference/typescript/api/client.gen/enumerations/FunctionCachePolicy)

The cache policy to use.

##### opts?

[`FunctionWithCachePolicyOpts`](/reference/typescript/api/client.gen/type-aliases/FunctionWithCachePolicyOpts)

#### Returns

`Function_`

---

### withCheck()

> **withCheck**(): `Function_`

Returns the function with a flag indicating it's a check.

#### Returns

`Function_`

---

### withDeprecated()

> **withDeprecated**(`opts?`): `Function_`

Returns the function with the provided deprecation reason.

#### Parameters

##### opts?

[`FunctionWithDeprecatedOpts`](/reference/typescript/api/client.gen/type-aliases/FunctionWithDeprecatedOpts)

#### Returns

`Function_`

---

### withDescription()

> **withDescription**(`description`): `Function_`

Returns the function with the given doc string.

#### Parameters

##### description

`string`

The doc string to set.

#### Returns

`Function_`

---

### withSourceMap()

> **withSourceMap**(`sourceMap`): `Function_`

Returns the function with the given source map.

#### Parameters

##### sourceMap

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The source map for the function definition.

#### Returns

`Function_`
