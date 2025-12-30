---
doc_id: ref/type-aliases/portforward
chunk_id: ref/type-aliases/portforward#chunk-2
heading_path: ["portforward", "Properties"]
chunk_type: prose
tokens: 55
summary: "> **backend**: `number`

Destination port for traffic."
---
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
