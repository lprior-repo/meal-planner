---
doc_id: tutorial/windmill/data-tables
chunk_id: tutorial/windmill/data-tables#chunk-5
heading_path: ["Data tables", "Database types"]
chunk_type: prose
tokens: 128
summary: "Database types"
---

## Database types

Windmill currently supports two backend database types for Data Tables:

### 1. Custom instance database

- Uses the **Windmill instance database**.
- Zero-setup, one-click provisioning.
- Requires **superadmin** to configure.
- Although the database exists at the _instance level_, it is only accessible to workspaces that define a data table pointing to it.
- See [Custom Instance Database](/docs/core_concepts/custom_instance_database) for more details.

### 2. Postgres resource

- Attach a **workspace Postgres resource** to the data table.
- Ideal when you want full control over database hosting, but still benefit from Windmill's credential management and workspace scoping.

---
