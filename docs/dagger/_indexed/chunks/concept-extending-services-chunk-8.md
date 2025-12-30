---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-8
heading_path: ["services", "Persist service state"]
chunk_type: prose
tokens: 40
summary: "Dagger cancels each service run after a 10 second grace period to avoid frequent restarts."
---
Dagger cancels each service run after a 10 second grace period to avoid frequent restarts. To avoid relying on the grace period, use a cache volume to persist a service's data.
