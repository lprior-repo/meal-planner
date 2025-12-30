---
doc_id: concept/getting-started/types
chunk_id: concept/getting-started/types#chunk-8
heading_path: ["types", "Service"]
chunk_type: table
tokens: 96
summary: "The `Service` type represents a content-addressed service providing TCP connectivity."
---
The `Service` type represents a content-addressed service providing TCP connectivity.

### Common operations

| Field | Description |
|-------|-------------|
| `endpoint` | Returns a URL or host:port pair to reach the service |
| `hostname` | Returns a hostname to reach the service |
| `ports` | Returns the list of ports provided by the service |
| `up` | Creates a tunnel that forwards traffic from the caller's network to the service |
