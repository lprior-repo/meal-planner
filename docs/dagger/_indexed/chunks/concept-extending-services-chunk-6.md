---
doc_id: concept/extending/services
chunk_id: concept/extending/services#chunk-6
heading_path: ["services", "Create interdependent services"]
chunk_type: prose
tokens: 70
summary: "Global hostnames can be assigned to services."
---
Global hostnames can be assigned to services. This feature is especially valuable for complex networking configurations, such as circular dependencies between services, by allowing services to reference each other by predefined hostnames, without requiring an explicit service binding.

Custom hostnames follow a structured format (`<host>.<module id>.<session id>.dagger.local`), ensuring unique identifiers across modules and sessions.
