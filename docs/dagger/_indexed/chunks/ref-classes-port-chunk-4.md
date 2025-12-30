---
doc_id: ref/classes/port
chunk_id: ref/classes/port#chunk-4
heading_path: ["port", "Methods"]
chunk_type: prose
tokens: 90
summary: "> **description**(): `Promise`<`string`\>

The port description."
---
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
