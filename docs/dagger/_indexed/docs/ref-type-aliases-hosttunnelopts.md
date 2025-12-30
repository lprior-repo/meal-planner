---
id: ref/type-aliases/hosttunnelopts
title: "Type Alias: HostTunnelOpts"
category: ref
tags: ["ref", "service", "type"]
---

# Type Alias: HostTunnelOpts

> **Context**: > **HostTunnelOpts** = `object`


> **HostTunnelOpts** = `object`

## Properties

### native?

> `optional` **native**: `boolean`

Map each service port to the same port on the host, as if the service were running natively.

Note: enabling may result in port conflicts.

---

### ports?

> `optional` **ports**: `PortForward`[]

Configure explicit port forwarding rules for the tunnel.

If a port's frontend is unspecified or 0, a random port will be chosen by the host.

If no ports are given, all of the service's ports are forwarded. If native is true, each port maps to the same port on the host. If native is false, each port maps to a random port chosen by the host.

If ports are given and native is true, the ports are additive.

## See Also

- [Documentation Overview](./COMPASS.md)
