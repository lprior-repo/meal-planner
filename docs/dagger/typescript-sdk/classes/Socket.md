# Class: Socket

A Unix or TCP/IP socket that can be mounted into a container.

## Extends

- `BaseClient`

## Constructors

### Constructor

> **new Socket**(`ctx?`, `_id?`): `Socket`

Constructor is used for internal usage only, do not create object from it.

#### Parameters

##### ctx?

`Context`

##### \_id?

[`SocketID`](/reference/typescript/api/client.gen/type-aliases/SocketID)

#### Returns

`Socket`

#### Overrides

`BaseClient.constructor`

## Methods

### id()

> **id**(): `Promise`<[`SocketID`](/reference/typescript/api/client.gen/type-aliases/SocketID)\>

A unique identifier for this Socket.

#### Returns

`Promise`<[`SocketID`](/reference/typescript/api/client.gen/type-aliases/SocketID)\>
