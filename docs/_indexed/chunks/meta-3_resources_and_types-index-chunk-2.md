---
doc_id: meta/3_resources_and_types/index
chunk_id: meta/3_resources_and_types/index#chunk-2
heading_path: ["Resources and resource types", "Create a resource"]
chunk_type: prose
tokens: 248
summary: "Create a resource"
---

## Create a resource

To create a resource using an existing type, go to the <a href="https://app.windmill.dev/resources" rel="nofollow">Resources </a> page and click "Add resource".

![Add a resource](./add_resource.png.webp 'Add a resource')

Just like most objects in Windmill, Resources have a path that defines their
permissions - see [ownership path prefix](./meta-16_roles_and_permissions-index.md).

Each **Resource** has a **Resource Type**, that defines what fields that
resource contains. Select one from the list and check the schema to see what
fields are present.

Resources commonly need to access secrets or re-use
[Variables](./meta-2_variables_and_secrets-index.md), for example, passwords or API
tokens. To insert a Variable into a Resource, use **Insert variable** (the `$`
sign button) and select a Variable. The name of a Variable will look like
`$var:<NAME_OF_VAR>`. When resources are called from a Script, the Variable
reference will be replaced by its value.

Resources can be assigned a description. It supports markdown.

![Resource description](./resource_description.png 'Resource description')

:::tip

It's a good practice to **link a script template to Resources**, so that users can
easily get started with it. You can use markdown in the description field to add
a link, for example:

```md
[example script with this resource](/scripts/add?template=script/template/path)
```

:::
