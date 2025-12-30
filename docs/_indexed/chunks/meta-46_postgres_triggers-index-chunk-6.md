---
doc_id: meta/46_postgres_triggers/index
chunk_id: meta/46_postgres_triggers/index#chunk-6
heading_path: ["Postgres triggers", "Limitations and examples"]
chunk_type: prose
tokens: 152
summary: "Limitations and examples"
---

## Limitations and examples

This section outlines the supported and unsupported combinations of tracking configurations, helping you avoid common setup issues and ensure your triggers work as intended.

### Valid configuration
You can combine:
- Schema-level tracking (e.g., `public` schema).
- Specific table tracking without selecting columns.

Example:  
Tracking the `bakery` table in the `paris` schema and all tables in the `private` and `public` schemas:

![Valid configuration example](./valid_config.png 'Valid configuration example')

### Invalid configuration
You cannot combine:
- Schema-level tracking with specific table tracking that includes column selection.

Example:  
Tracking all tables in the `public` schema and the `bakery` table in the `paris` schema with selected columns (`name` and `address`):

![Invalid configuration example](./invalid_config.png 'Invalid configuration example')

---
