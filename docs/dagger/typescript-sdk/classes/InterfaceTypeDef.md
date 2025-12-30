# Class: InterfaceTypeDef

A definition of a custom interface defined in a Module.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new InterfaceTypeDef**(`ctx?`, `_id?`, `_description?`, `_name?`, `_sourceModuleName?`): `InterfaceTypeDef`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`InterfaceTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InterfaceTypeDefID)

##### \_description?

`string`

##### \_name?

`string`

##### \_sourceModuleName?

`string`

#### Returns

`InterfaceTypeDef`

#### Overrides

`BaseClient.constructor`

## Methods

### description()

> **description**(): `Promise`<`string`\>

The doc string for the interface, if any.

#### Returns

`Promise`<`string`\>

---

### functions()

> **functions**(): `Promise`<[`Function_`](/reference/typescript/api/client.gen/classes/Function)\[\]>

Functions defined on this interface, if any.

#### Returns

`Promise`<[`Function_`](/reference/typescript/api/client.gen/classes/Function)\[\]>

---

### id()

> **id**(): `Promise`<[`InterfaceTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InterfaceTypeDefID)\>

A unique identifier for this InterfaceTypeDef.

#### Returns

`Promise`<[`InterfaceTypeDefID`](/reference/typescript/api/client.gen/type-aliases/InterfaceTypeDefID)\>

---

### name()

> **name**(): `Promise`<`string`\>

The name of the interface.

#### Returns

`Promise`<`string`\>

---

### sourceMap()

> **sourceMap**(): [`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

The location of this interface declaration.

#### Returns

[`SourceMap`](/reference/typescript/api/client.gen/classes/SourceMap)

---

### sourceModuleName()

> **sourceModuleName**(): `Promise`<`string`\>

If this InterfaceTypeDef is associated with a Module, the name of the module. Unset otherwise.

#### Returns

`Promise`<`string`\>
