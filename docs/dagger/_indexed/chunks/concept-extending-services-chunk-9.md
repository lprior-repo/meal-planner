---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-9
heading_path: ["services", "Start and stop services"]
chunk_type: prose
tokens: 94
summary: "Services are designed to be expressed as a Directed Acyclic Graph (DAG) with explicit bindings al..."
---
Services are designed to be expressed as a Directed Acyclic Graph (DAG) with explicit bindings allowing services to be started lazily, just like every other DAG node. But sometimes, you may need to explicitly manage the lifecycle in a Dagger Function.

For example, this may be needed if the application in the service has certain behavior on shutdown (such as flushing data) that needs careful coordination with the rest of your logic.
