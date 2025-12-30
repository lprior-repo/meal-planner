---
doc_id: meta/15_authentification/index
chunk_id: meta/15_authentification/index#chunk-4
heading_path: ["Authentication", "Adding Users to a Workspace"]
chunk_type: prose
tokens: 508
summary: "Adding Users to a Workspace"
---

## Adding Users to a Workspace

Once added to an instance, users can create their own workspace. However, by default they will not be invited to any workspace.

Windmill can be configured to remove the ability for non-[superadmins](./meta-16_roles_and_permissions-index.md) to create workspace using the: CREATE_WORKSPACE_REQUIRE_SUPERADMIN env variable.

### Manually

From the Workspace settings, in the `Users & Invites` tab, any admin can manually add users, filling:

- `email`: the email address linked to the Windmill account.
- `user`: the username (specific to workspace).

Users can be given roles Operator, Developer or Admin. Any user can also be manually removed.

![Manually Add User to Workspace](./add_user_to_workspace.png 'Manually add user to workspace')

The user will be added to the workspace even if no Windmill account is created yet. Once access is created to a Windmill account, the workspace will be available from the "Select a workspace" menu.

![Select a workspace](./select_workspace.png 'Select a workspace')

You can also choose to invite users instead of adding them directly. You only need to fill in the users' email and they will have to pick the username.

![Invite a user manually](./invite_manually.png 'Invite a user manually')

> Add the user's email to the list of invites, with the appropriate [level of permission](./meta-16_roles_and_permissions-index.md).

<br />

![Select an invited workspace](./get_invite.png 'Select an invited workspace')

> The invite will be available in the "Invites to join a Workspace" section.

<br />

![Set Username](./set_username.png 'Set a Username')

> From where the users can set their username.

<br />

If [SMTP is configured](./meta-18_instance_settings-index.md#smtp), the invite will be sent even if no Windmill account is created yet. Once access is created to a Windmill account, an invite will be available from the "Select a workspace" menu.

### Auto invite

You can send auto-invites to the workspace to users from your domain.

From the Workspace settings, in the `Users & Invites` tab, go to "Set auto-invite to [domain]".

![Auto Invites](./auto_invite.png 'Auto invites')

This will add users to the list of Pending Invites, from where you can still manually cancel any invite.

At last, you can enable "Auto-invited users to join as operators".

![Pending invites](./pending_invites.png 'Pending invites')

Once access is created to a Windmill account, an invite will be available in the "Invites to join a Workspace" section.

![Select an invited workspace](./get_invite.png 'Select an invited workspace')

From where each user can set their username.

![Set Username](./set_username.png 'Set a Username')
