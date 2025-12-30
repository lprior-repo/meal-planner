---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-2
heading_path: ["services", "Service containers"]
chunk_type: prose
tokens: 70
summary: "Services instantiated by a Dagger Function run in service containers, which have the following ch..."
---
Services instantiated by a Dagger Function run in service containers, which have the following characteristics:

- Each service container has a canonical, content-addressed hostname and an optional set of exposed ports.
- Service containers are started just-in-time, de-duplicated, and stopped when no longer needed.
- Service containers are health checked prior to running clients.
