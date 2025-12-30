---
doc_id: meta/2_variables_and_secrets/index
chunk_id: meta/2_variables_and_secrets/index#chunk-6
heading_path: ["Variables and secrets", "Add a variable or secret"]
chunk_type: prose
tokens: 91
summary: "Add a variable or secret"
---

## Add a variable or secret

You can define variables from the Variables page. Like all objects in
Windmill, variable ownership is defined by the path - see
[ownership path prefix](./meta-16_roles_and_permissions-index.md).

Variables also have a name, generated from the path, and names are used to
access variables from scripts.

A variable can be made secret. In this case, its value will not be visible outside of a script.

![Add variable](./add_variable.png.webp)
