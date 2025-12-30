# Type Alias: ServiceUpOpts

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
