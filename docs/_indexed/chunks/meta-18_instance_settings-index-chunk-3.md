---
doc_id: meta/18_instance_settings/index
chunk_id: meta/18_instance_settings/index#chunk-3
heading_path: ["Instance settings", "Global users"]
chunk_type: prose
tokens: 217
summary: "Global users"
---

## Global users

Global Users are users of the Windmill instance. They are not associated with any workspace and can be assigned to any workspace (from the workspace settings).

From there you can manually add a user to the instance, giving an email and a password. Users can be set to User, [Devops](./meta-16_roles_and_permissions-index.md#devops) or Superadmin [roles](./meta-16_roles_and_permissions-index.md#superadmin).

You can also enable automatic username creation from emails. Usernames will be shared accross workspaces. We recommend setting it to avoid duplicated usernames.

A more common way to add users is to use [SSO/OAuth](#authoauth).

For each user, you can see Email, Auth (manually-set password or Auth methods), Name, Kind ([Developer](./meta-16_roles_and_permissions-index.md#developer) or [Operator](./meta-16_roles_and_permissions-index.md#operator) where an operator at the instace level is an operator in all workspaces they are members of), and Role (User or [Superadmin](./meta-16_roles_and_permissions-index.md#superadmin)).

You can also toggle on 'Show active users only' to show only users who have performed at least one action in the last 30 days. Only those users are counted in our [Pricing](/pricing).

![Global Users](./global_users.png "Global Users")
