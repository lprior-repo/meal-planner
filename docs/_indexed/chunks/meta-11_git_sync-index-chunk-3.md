---
doc_id: meta/11_git_sync/index
chunk_id: meta/11_git_sync/index#chunk-3
heading_path: ["Git sync", "Filters"]
chunk_type: prose
tokens: 270
summary: "Filters"
---

## Filters

### Path filters

Only scripts, flows and apps with their path matching one of the set filters will be synced to the Git repositories below. The filters allow `*'` and `**'` characters, with `*'` matching any character allowed in paths until the next slash (`/`) and `**'` matching anything including slashes.
By default everything in folders (with rule `f/**`) will be synced.

You can configure:

- **Include paths**: Primary patterns for what to sync (e.g., `f/**`)
- **Exclude paths**: Patterns to exclude after include checks

### Type filters

On top of the filter path [above](#path-filters), you can include only certain type of object to be synced with the Git repository.
By default everything is synced.

You can filter on:

- **Scripts** - Individual scripts
- **Flows** - Workflow definitions
- **Apps** - Application definitions
- **Folders** - Folder structure
- **Resources** - Resource instances
- **Variables** - Workspace variables
  - **Include secrets** - Option to include secret variables
- **Schedules** - Scheduled job definitions
- **Resource types**
- **Users** - User definitions
- **Groups** - Group definitions
- **Triggers** - Event triggers (HTTP routes, WebSocket, Postgres, Kafka, NATS, SQS, GCP Pub/Sub, MQTT)
- **Workspace settings** - Global workspace configuration
- **Encryption key** - Workspace encryption key
