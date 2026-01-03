---
doc_id: concept/guides/root-project
chunk_id: concept/guides/root-project#chunk-1
heading_path: ["Root-level project"]
chunk_type: prose
tokens: 117
summary: "Root-level project"
---

# Root-level project

> **Context**: Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, mainte

Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, maintenance, or process oriented tasks can be ran. moon supports this through a concept known as a root-level project.

Begin by adding the root to [`projects`](/docs/config/workspace#projects) with a source value of `.` (current directory relative from the workspace).

.moon/workspace.yml

```yaml
