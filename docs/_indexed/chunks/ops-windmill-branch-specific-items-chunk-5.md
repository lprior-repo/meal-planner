---
doc_id: ops/windmill/branch-specific-items
chunk_id: ops/windmill/branch-specific-items#chunk-5
heading_path: ["Branch-specific items", "File path transformation"]
chunk_type: prose
tokens: 196
summary: "File path transformation"
---

## File path transformation

### Transform logic

When syncing branch-specific items, paths are transformed as follows:

**Pull operation** (Windmill workspace → local):
- Windmill workspace: `u/alex/database.resource.yaml`
- Local: `u/alex/database.main.resource.yaml` (on main branch)
- Windmill workspace: `u/alex/orders.kafka_trigger.yaml`
- Local: `u/alex/orders.main.kafka_trigger.yaml` (on main branch)

**Push operation** (local → Windmill workspace):
- Local: `u/alex/database.dev.resource.yaml` (on dev branch)
- Windmill workspace: `u/alex/database.resource.yaml`
- Local: `u/alex/orders.dev.kafka_trigger.yaml` (on dev branch)
- Windmill workspace: `u/alex/orders.kafka_trigger.yaml`

### Resource files

Resources can include associated files (certificates, config files, etc.) alongside their YAML definitions. These files follow the same branch-specific transformation:

**Resource files naming**:
- Base file: `u/alex/certificate.resource.file.pem`
- Branch-specific: `u/alex/certificate.dev.resource.file.pem`

When a resource YAML file is marked as branch-specific, all associated resource files are automatically treated as branch-specific as well.

### Supported file types

These file types support branch-specific transformation:

- **Variables**: `*.variable.yaml`
- **Resources**: `*.resource.yaml` and resource files (`*.resource.file.*`)
- **Triggers**: `*.kafka_trigger.yaml`, `*.http_trigger.yaml`, `*.websocket_trigger.yaml`, `*.nats_trigger.yaml`, `*.postgres_trigger.yaml`, `*.mqtt_trigger.yaml`, `*.sqs_trigger.yaml`, `*.gcp_trigger.yaml`
