---
doc_id: meta/8_groups_and_folders/index
chunk_id: meta/8_groups_and_folders/index#chunk-2
heading_path: ["Groups and folders", "Folders"]
chunk_type: prose
tokens: 130
summary: "Folders"
---

## Folders

Folders group various items, such as scripts, flows, resources, and schedules, together and assign [role](./meta-16_roles_and_permissions-index.md#roles-in-windmill)-based access control permissions to groups and individual users.

![Folders](./3-folders.png 'Folders')

Folders should represent projects, and we recommend assigning permissions to groups. You should have as many top-level folders that you have different projects/permission scopes.

### Subfolders

You can have as many subfolders as you want but only the top-level folder will have permissions one can inherit from.

To use subfolders, you just need to have '/' in the last part of the [path](./meta-16_roles_and_permissions-index.md#path) of an item, like you would do on a filesystem.
