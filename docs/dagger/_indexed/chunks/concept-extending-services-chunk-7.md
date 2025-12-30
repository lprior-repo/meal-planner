---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-7
heading_path: ["services", "Use service endpoints"]
chunk_type: prose
tokens: 83
summary: "Every service has an endpoint, and this endpoint can be obtained via the Dagger API."
---
Every service has an endpoint, and this endpoint can be obtained via the Dagger API. This feature is typically useful in two scenarios:

- When a target container (which you bind the service to) is unable to resolve the service with the bound alias.
- When a service needs to be accessible (for example, over standard HTTP) without needing another container to access it.
