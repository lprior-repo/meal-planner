---
doc_id: concept/system/permissions
chunk_id: concept/system/permissions#chunk-2
heading_path: ["Permissions", "Permission levels"]
chunk_type: prose
tokens: 133
summary: "Permission levels"
---

## Permission levels
The following table roughly defines the capabilities of each role

| Group            | Capabilities                                                 |
| ---------------- | ------------------------------------------------------------ |
| logged in user   | Can do almost nothing without a group.                        |
| guest            | - Search and view recipes<br />- write comments <br />- change user settings (e.g. language, theme, password) |
| user             | Can do basically everything except for what admins can do    |
| admin            | - Create, edit and delete external storage<br />- Create, edit and delete synced paths |
| django superuser | Ignores all permission checks and can access admin interface |
