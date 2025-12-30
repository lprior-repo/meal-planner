# Class: Port

A port exposed by a container.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Port**(`ctx?`, `_id?`, `_description?`, `_experimentalSkipHealthcheck?`, `_port?`, `_protocol?`): `Port`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`PortID`](/reference/typescript/api/client.gen/type-aliases/PortID)

##### \_description?

`string`

##### \_experimentalSkipHealthcheck?

`boolean`

##### \_port?

`number`

##### \_protocol?

[`NetworkProtocol`](/reference/typescript/api/client.gen/enumerations/NetworkProtocol)

#### Returns

`Port`

#### Overrides

`BaseClient.constructor`

## Methods

### description()

> **description**(): `Promise`<`string`\>

The port description.

#### Returns

`Promise`<`string`\>

---

### experimentalSkipHealthcheck()

> **experimentalSkipHealthcheck**(): `Promise`<`boolean`\>

Skip the health check when run as a service.

#### Returns

`Promise`<`boolean`\>

---

### id()

> **id**(): `Promise`<[`PortID`](/reference/typescript/api/client.gen/type-aliases/PortID)\>

A unique identifier for this Port.

#### Returns

`Promise`<[`PortID`](/reference/typescript/api/client.gen/type-aliases/PortID)\>

---

### port()

> **port**(): `Promise`<`number`\>

The port number.

#### Returns

`Promise`<`number`\>

---

### protocol()

> **protocol**(): `Promise`<[`NetworkProtocol`](/reference/typescript/api/client.gen/enumerations/NetworkProtocol)\>

The transport layer protocol.

#### Returns

`Promise`<[`NetworkProtocol`](/reference/typescript/api/client.gen/enumerations/NetworkProtocol)\>
