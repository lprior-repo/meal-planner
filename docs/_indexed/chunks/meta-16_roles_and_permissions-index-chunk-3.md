---
doc_id: meta/16_roles_and_permissions/index
chunk_id: meta/16_roles_and_permissions/index#chunk-3
heading_path: ["Roles and permissions", "Workspace"]
chunk_type: prose
tokens: 105
summary: "Workspace"
---

## Workspace

Every nameable or pathable entity in Windmill has a workspace attached to it.
This includes:

- users
- groups
- scripts
- resources
- variables
- schedules
- jobs

Windmill's entire database is partitioned by workspaces such that users, teams
and orgs can safely co-locate without risk of leakage.

Any user can create their own workspace. When a user creates a workspace, the user is an
admin of such workspace and he can invite others to join his workspace.
