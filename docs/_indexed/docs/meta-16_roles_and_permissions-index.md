---
id: meta/16_roles_and_permissions/index
title: "Roles and permissions"
category: meta
tags: ["16_roles_and_permissions", "roles", "meta"]
---

import DocCard from '@site/src/components/DocCard';

# Roles and permissions

> **Context**: import DocCard from '@site/src/components/DocCard';

Windmill provides a roles and permissions system that allows you to control access and manage permissions within your instance and workspaces. Different roles have different levels of access to scripts, flows, apps, and other entities in Windmill.

Everybody having access to a Windmill instance is considered a User.

Recap of how roles within an instance and a workspace are structured:

![Recap Instances and Members](./instance_members.png 'Recap Instances and Members')

Recap of how are permissioned items (scripts, flows, apps, resources, variables, schedules, jobs) within a workspace:

![Recap Item Permissions](./permissions.png 'Recap Item Permissions')

## Users

Users are uniquely identified globally by their email. They also have a unique username with respect to each workspace they are members of.

In terms of billing for Windmill [Enterprise Edition](/pricing), we only count active users, i.e. users who have at least logged in to the platform in the last 30 days according to the audit logs. [Operators](#operator) (i.e. users who are Operators in all workspaces they are members of) are counted as half of a regular seat. Logging in once in 30 days is enough to be considered 'Active'.

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

## Roles in Windmill

Users can be given different levels of permissions:

### Superadmin

The superadmin role has the highest level of access and can manage the entire Windmill instance. Only superadmins can access the dedicated 'admins' workspace. Also by default, superadmins have access to all workspaces as admins of those workspaces. When an admin does an action as a user of a workspace he is not a member of and as such as no username in, their email is used in lieu of the username. Windmill can be configured to remove the ability for non-superadmins to create workspace using the: CREATE_WORKSPACE_REQUIRE_SUPERADMIN env variable.

### Devops

The devops role is also set at the instance level. Conceptually, it can be understood as a "readonly Superadmin". Devops users have read rights over what is usually only visible to [superadmins](#superadmin), such as [Service Logs](./meta-36_service_logs-index.md) or [Critical Alerts](./meta-37_critical_alerts-index.md) while keeping write operations to a minimum. Contrary to the superadmin, this role does not supersede other roles like [workspace admins](#admin).

### Admin

At the [workspace](#workspace) level, admins have the ability to manage a specific Windmill workspace and users within that workspace. They can see and edit all scripts, flows, apps, and other entities within the workspace. Admins have the power to create, modify, and delete entities and can manage permissions within the workspace.

At the [folder](./meta-8_groups_and_folders-index.md#folders) level, an admin of a folder has read, write and archive access to all the elements inside the folders ([scripts](./meta-0_scripts_quickstart-index.md), [flows](./meta-6_flows_quickstart-index.md), [apps](./meta-7_apps_quickstart-index.md), [resources](./meta-3_resources_and_types-index.md), [schedules](./meta-1_scheduling-index.md)) and can manage the permissions as well as add new admins.

### Developer

Developers can execute and view scripts, flows, and apps within a workspace. Developers see the full interface of Windmill and contrary to the Operators, they have the ability to create and edit scripts, flows and apps. Developers have read and write access to the entities they create or have been [granted access to by others](./meta-8_groups_and_folders-index.md).

### Operator

Operators have limited access within a workspace. They can only execute and view scripts, flows, and apps that they have visibility on, and only those that are within their allowed path or [folders](./meta-8_groups_and_folders-index.md). Operators do not have the ability to create or modify entities.
The recommended way to share scripts and flows with operators is through [auto-generated apps](./meta-6_auto_generated_uis-index.md).
With the second option being of sharing the script and [variables](./meta-2_variables_and_secrets-index.md) it depends on (but operators won't be able to load variable directly from the UI/API, only use them within the scripts they have access to).

From the workspace settings, you can configure the operator visibility settings for your workspace. In particular, you can allow/disallow operators to view:

- [Runs](./meta-5_monitor_past_and_future_runs-index.md)
- [Schedules](./meta-1_scheduling-index.md)
- [Resources](./meta-3_resources_and_types-index.md)
- [Variables](./meta-2_variables_and_secrets-index.md)
- [Triggers](./meta-8_triggers-index.md)
- [Audit logs](./meta-14_audit_logs-index.md)
- [Groups](./meta-8_groups_and_folders-index.md#groups)
- [Folders](./meta-8_groups_and_folders-index.md#folders)
- [Workers](./meta-9_worker_groups-index.md)

Regarding to [Pricing](/pricing), operators are counted as half of a regular seat ([developers](#developer)) as long as they are operators in all workspaces they are members of. Operators are not set as the instance-level. On the billing side, 1 developer seat or 2 operators seats count as 1 seat, there is no need to differentiate between developers and operators when purchasing the license.

### Anonymous app viewers

Anonymous app viewers are individuals who can access and view Windmill apps without being a user but by knowing the [secret URL](../../apps/0_toolbar.mdx#deploy) that allows app viewing. They do not have any editing or privileges to execute scripts and flows. The apps that they see execute the scripts and flows that are part of the app but only on behalf of the app author. The anonymous user cannot execute any of the scripts and flows part of the apps outside of the inputs authorized by the app through a policy that is automatically generated by the app.

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Groups and folders"
		description="Groups classify users with shared permissions, while folders group items and assign role-based access control."
		href="/docs/core_concepts/groups_and_folders"
	/>
	<DocCard
		color="orange"
		title="Publish Publicly (App editor)"
		description="The app can be accessed by anyone who knows the secret URL."
		href="/docs/apps/toolbar#deploy"
	/>
</div>

## Permissions and access control

Windmill implements a fine-grained Access Control List (ACL) by default, allowing you to define permissions for various entities within the system, including:

- [groups](./meta-8_groups_and_folders-index.md#groups)
- [folders](./meta-8_groups_and_folders-index.md#folders)
- [scripts](./meta-0_scripts_quickstart-index.md)
- [resources](./meta-3_resources_and_types-index.md)
- [variables](./meta-2_variables_and_secrets-index.md)
- [schedules](./meta-1_scheduling-index.md)
- [jobs](./meta-20_jobs-index.md)

There are 3 possible roles for each item:

- **Admin** (Owner): has read, write and archive access. Admins of an item can't delete it unless they are admins of the workspace.
- **Writer**: has read, write and archive access. They can't archive nor change the [path](#path) of the item.
- **Viewer**: has read-only access to the item.

Admins of a workspace have elevated privileges and can read and write over everything within the workspace, disregarding ACLs.

The ACLs are defined by the path of the item.

### Path

Windmill uniquely identifies [scripts](./meta-0_scripts_quickstart-index.md), [variables](./meta-2_variables_and_secrets-index.md), [resources](./meta-3_resources_and_types-index.md), [schedules](./meta-1_scheduling-index.md) - and in general almost everything - using their path. The paths are globally unique within the category of entities they represent. In short, a Resource and a Schedule for example can have the same path, without conflict.

Each entity's ACL defines its owner and specifies the read and write permissions. By default, only the owner of an entity has read and write access to it. Entities can be explicitly shared with other [groups](./meta-8_groups_and_folders-index.md#groups) and users in either read-only or read and write mode through [folders](./meta-8_groups_and_folders-index.md#folders). Write mode implicitly includes read permission.

A path is either inside a user space `u/<user>/<path>` or inside a folder `f/<folder>/<path>`. The path defines permissions with:

- a User: that user will be by default given read, write and archive access on the item (`u/henri/amazed_postgresql`).
- a Folder: the item will be available to the users having access to the folder, with its own levels of permissions (`f/data_team/amazed_postgresql`).

You can modify paths, but this may break other dependent entities. For scripts, flows, and apps, you will see a warning with a list of affected entities:

![Path Renaming](./path_renaming.png 'Path Renaming')

### Extra permissions

For each item (script, flow, app, resource, variable, schedule), you can define extra permissions clicking on the `⋮` icon, then `Share`.

Extra permissions can be given to a user or a group, with the possibility to give them the role of Viewer, or Writer.

![Extra Permissions](./share.png 'Extra Permissions')

![Share Menu](./share_menu.png 'Share Menu')

### Example of permissions

For example here a new SQL Resource is being given access to a user `username` with view, write and archive access:

![Add User to Resource](./add_user_path.png.webp 'Resource given to a User')

Here the new SQL Resource is being given access to a folder `data_team`...

![Add Folder to Resource](./add_folder.png.webp 'Resource given to a Folder')

... folder that can give Admin, Writer or Viewer accesses to users or [groups](./meta-8_groups_and_folders-index.md#groups).

![Add Users to Folder](./add_users.png.webp 'Folder having its own levels of permission')

Also, [extra permission](#extra-permissions) was given to Ruben as viewer.

![Extra Permissions Example](./extra_example.png 'Extra Permissions Example')

<br />

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Groups and folders"
		description="Groups classify users with shared permissions, while folders group items and assign role-based access control."
		href="/docs/core_concepts/groups_and_folders"
	/>
</div>


## See Also

- [Recap Instances and Members](./instance_members.png 'Recap Instances and Members')
- [Recap Item Permissions](./permissions.png 'Recap Item Permissions')
- [Enterprise Edition](/pricing)
- [Operators](#operator)
- [superadmins](#superadmin)
