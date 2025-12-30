---
doc_id: concept/features/services
chunk_id: concept/features/services#chunk-1
heading_path: ["services"]
chunk_type: prose
tokens: 125
summary: "> **Context**: Dagger Functions support service containers, enabling users to spin up additional ..."
---
# Ephemeral Services

> **Context**: Dagger Functions support service containers, enabling users to spin up additional services (as containers) and communicate with those services from th...


Dagger Functions support service containers, enabling users to spin up additional services (as containers) and communicate with those services from their workflows.

This makes it possible to:

- Instantiate and return services from a Dagger Function, and then:
  - Use those services in other Dagger Functions (container-to-container networking)
  - Use those services from the calling host (container-to-host networking)
- Expose host services for use in a Dagger Function (host-to-container networking).
