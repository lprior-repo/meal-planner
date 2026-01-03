---
doc_id: concept/moonrepo/template
chunk_id: concept/moonrepo/template#chunk-8
heading_path: ["template.{pkl,yml}", "Frontmatter"]
chunk_type: code
tokens: 219
summary: "Frontmatter"
---

## Frontmatter

The following settings *are not* available in `template.yml`, but can be defined as frontmatter at the top of a template file. View the [code generation guide](/docs/guides/codegen#frontmatter) for more information.

### `force`

When enabled, will always overwrite a file of the same name at the destination path, and will bypass any prompting in the terminal.

```
---
force: true
---
Some template content!
```

### `to`

Defines a custom file path, relative from the destination root, in which to create the file. This will override the file path within the template folder, and allow for conditional rendering and engine filters to be used.

```
{% set component_name = name | pascal_case %}
---
to: components/{{ component_name }}.tsx
---
export function {{ component_name }}() {
  return <div />;
}
```

### `skip`

When enabled, the template file will be skipped while writing to the destination path. This setting can be used to conditionally render a file.

```
---
skip: {{ name == "someCondition" }}
---
Some template content!
```
