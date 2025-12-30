---
id: ref/type-aliases/portforward
title: "Type Alias: PortForward"
category: ref
tags: ["ref", "type"]
---

# Type Alias: PortForward

> **Context**: > **PortForward** = `object`


> **PortForward** = `object`

## Properties

### backend

> **backend**: `number`

Destination port for traffic.

---

### frontend?

> `optional` **frontend**: `number`

Port to expose to clients. If unspecified, a default will be chosen.

---

### protocol?

> `optional` **protocol**: [`NetworkProtocol`](/reference/typescript/api/client.gen/enumerations/NetworkProtocol)

Transport layer protocol to use for traffic.

## See Also

- [Documentation Overview](./COMPASS.md)
