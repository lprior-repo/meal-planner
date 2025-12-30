---
doc_id: meta/53_custom_instance_database/index
chunk_id: meta/53_custom_instance_database/index#chunk-1
heading_path: ["Custom Instance Database"]
chunk_type: prose
tokens: 143
summary: "Custom Instance Database"
---

# Custom Instance Database

> **Context**: In the past, storing data inside a SQL database required you to setup a database outside of Windmill, and connect to it using a Resource. Custom Insta

In the past, storing data inside a SQL database required you to setup a database outside of Windmill, and connect to it using a Resource. Custom Instance Databases allow you to use the Windmill postgres database as a persistent storage for your workspace, without any external setup.

These databases can only be configured by superadmins. They are used through abstractions like [Data Tables](/docs/core_concepts/persistent_storage/data_tables) or [Ducklakes](/docs/core_concepts/persistent_storage/ducklake),
which provide safe access to workspace members without ever exposing database credentials.
