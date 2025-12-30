---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-1
heading_path: ["services"]
chunk_type: prose
tokens: 165
summary: "> **Context**: Dagger Functions support service containers, enabling users to spin up additional ..."
---
# Services

> **Context**: Dagger Functions support service containers, enabling users to spin up additional long-running services (as containers) and communicate with those ser...


Dagger Functions support service containers, enabling users to spin up additional long-running services (as containers) and communicate with those services from Dagger Functions.

This makes it possible to:

- Instantiate and return services from a Dagger Function, and then:
  - Use those services in other Dagger Functions (container-to-container networking)
  - Use those services from the calling host (container-to-host networking)
- Expose host services for use in a Dagger Function (host-to-container networking).

Some common scenarios for using services with Dagger Functions are:

- Running a database service for local storage or testing
- Running end-to-end integration tests against a service
- Running sidecar services
