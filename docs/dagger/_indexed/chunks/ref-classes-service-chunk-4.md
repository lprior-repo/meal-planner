---
doc_id: ref/classes/service
chunk_id: ref/classes/service#chunk-4
heading_path: ["service", "Methods"]
chunk_type: prose
tokens: 376
summary: "> **endpoint**(`opts?"
---
### endpoint()

> **endpoint**(`opts?`): `Promise`<`string`\>

Retrieves an endpoint that clients can use to reach this container.

If no port is specified, the first exposed port is used. If none exist an error is returned.

If a scheme is specified, a URL is returned. Otherwise, a host:port pair is returned.

#### Parameters

#### opts?

[`ServiceEndpointOpts`](/reference/typescript/api/client.gen/type-aliases/ServiceEndpointOpts)

#### Returns

`Promise`<`string`\>

---

### hostname()

> **hostname**(): `Promise`<`string`\>

Retrieves a hostname which can be used by clients to reach this container.

#### Returns

`Promise`<`string`\>

---

### id()

> **id**(): `Promise`<[`ServiceID`](/reference/typescript/api/client.gen/type-aliases/ServiceID)\>

A unique identifier for this Service.

#### Returns

`Promise`<[`ServiceID`](/reference/typescript/api/client.gen/type-aliases/ServiceID)\>

---

### ports()

> **ports**(): `Promise`<[`Port`](/reference/typescript/api/client.gen/classes/Port)\[\]>

Retrieves the list of ports provided by the service.

#### Returns

`Promise`<[`Port`](/reference/typescript/api/client.gen/classes/Port)\[\]>

---

### start()

> **start**(): `Promise`<`Service`\>

Start the service and wait for its health checks to succeed.

Services bound to a Container do not need to be manually started.

#### Returns

`Promise`<`Service`\>

---

### stop()

> **stop**(`opts?`): `Promise`<`Service`\>

Stop the service.

#### Parameters

#### opts?

[`ServiceStopOpts`](/reference/typescript/api/client.gen/type-aliases/ServiceStopOpts)

#### Returns

`Promise`<`Service`\>

---

### sync()

> **sync**(): `Promise`<`Service`\>

Forces evaluation of the pipeline in the engine.

#### Returns

`Promise`<`Service`\>

---

### terminal()

> **terminal**(`opts?`): `Service`

#### Parameters

#### opts?

[`ServiceTerminalOpts`](/reference/typescript/api/client.gen/type-aliases/ServiceTerminalOpts)

#### Returns

`Service`

---

### up()

> **up**(`opts?`): `Promise`<`void`\>

Creates a tunnel that forwards traffic from the caller's network to this service.

#### Parameters

#### opts?

[`ServiceUpOpts`](/reference/typescript/api/client.gen/type-aliases/ServiceUpOpts)

#### Returns

`Promise`<`void`\>

---

### with()

> **with**(`arg`): `Service`

Call the provided function with current Service.

This is useful for reusability and readability by not breaking the calling chain.

#### Parameters

#### arg

(`param`) => `Service`

#### Returns

`Service`

---

### withHostname()

> **withHostname**(`hostname`): `Service`

Configures a hostname which can be used by clients within the session to reach this container.

#### Parameters

#### hostname

`string`

The hostname to use.

#### Returns

`Service`
