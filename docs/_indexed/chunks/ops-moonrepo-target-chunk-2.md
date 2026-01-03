---
doc_id: ops/moonrepo/target
chunk_id: ops/moonrepo/target#chunk-2
heading_path: ["Targets", "Common scopes"]
chunk_type: prose
tokens: 67
summary: "Common scopes"
---

## Common scopes

These scopes are available for both running targets and configuring them.

### By project

The most common scope is the project scope, which requires the name of a project, as defined in [`.moon/workspace.yml`](/docs/config/workspace). When paired with a task name, it will run a specific task from that project.

```bash
