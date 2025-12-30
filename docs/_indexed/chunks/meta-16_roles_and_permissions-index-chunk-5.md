---
doc_id: meta/16_roles_and_permissions/index
chunk_id: meta/16_roles_and_permissions/index#chunk-5
heading_path: ["Roles and permissions", "Permissions and access control"]
chunk_type: prose
tokens: 650
summary: "Permissions and access control"
---

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
