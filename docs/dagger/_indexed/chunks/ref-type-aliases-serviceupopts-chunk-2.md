---
doc_id: ref/type-aliases/serviceupopts
chunk_id: ref/type-aliases/serviceupopts#chunk-2
heading_path: ["serviceupopts", "Properties"]
chunk_type: prose
tokens: 58
summary: "> `optional` **ports**: [`PortForward`](/reference/typescript/api/client."
---
### ports?

> `optional` **ports**: [`PortForward`](/reference/typescript/api/client.gen/type-aliases/PortForward)[]

List of frontend/backend port mappings to forward.

Frontend is the port accepting traffic on the host, backend is the service port.

---

### random?

> `optional` **random**: `boolean`

Bind each tunnel port to a random port on the host.
