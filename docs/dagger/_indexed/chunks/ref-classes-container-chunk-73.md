---
doc_id: ref/classes/container
chunk_id: ref/classes/container#chunk-73
heading_path: ["container", "Methods", "withServiceBinding()"]
chunk_type: prose
tokens: 125
summary: "> **withServiceBinding**(`alias`, `service`): `Container`

Establish a runtime dependency from a ..."
---
> **withServiceBinding**(`alias`, `service`): `Container`

Establish a runtime dependency from a container to a network service.

The service will be started automatically when needed and detached when it is no longer needed, executing the default command if none is set.

The service will be reachable from the container via the provided hostname alias.

The service dependency will also convey to any files or directories produced by the container.

#### Parameters

#### alias

`string`

Hostname that will resolve to the target service (only accessible from within this container)

#### service

[`Service`](/reference/typescript/api/client.gen/classes/Service)

The target service

#### Returns

`Container`

---
