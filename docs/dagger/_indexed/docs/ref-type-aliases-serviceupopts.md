---
id: ref/type-aliases/serviceupopts
title: "Type Alias: ServiceUpOpts"
category: ref
tags: ["ref", "service", "type"]
---

# Type Alias: ServiceUpOpts

> **Context**: > **ServiceUpOpts** = `object`


> **ServiceUpOpts** = `object`

## Properties

### ports?

> `optional` **ports**: [`PortForward`](/reference/typescript/api/client.gen/type-aliases/PortForward)[]

List of frontend/backend port mappings to forward.

Frontend is the port accepting traffic on the host, backend is the service port.

---

### random?

> `optional` **random**: `boolean`

Bind each tunnel port to a random port on the host.

## See Also

- [Documentation Overview](./COMPASS.md)
