---
doc_id: concept/3_cli/resource
chunk_id: concept/3_cli/resource#chunk-3
heading_path: ["Resources", "Pushing a resource"]
chunk_type: code
tokens: 210
summary: "Pushing a resource"
---

## Pushing a resource

The `wmill resource push` command is used to push a local resource, overriding any existing remote versions.

```bash
wmill resource push <file_path> <remote_path>
```text

### Arguments

| Argument      | Description                                          |
| ------------- | ---------------------------------------------------- |
| `file_path`   | The path to the resource file to push.               |
| `remote_path` | The remote path where the resource should be pushed. |

### Resource specification

We support both JSON and YAML files. The structure of the file is as follows:

```yaml
value: <value>
description: <description>
resource_type: <resource_type>
is_oauth: <is_oauth>
```text

```JSON
{
    "value": "<value>",
    "description": "<description>",
    "resource_type": "<resource_type>",
    "is_oauth": "<is_oauth>"
}
```

- value (required): Represents the actual content or value of the resource.
- description (optional): A string providing additional information or a description of the resource.
- resource_type (required): A resource type
- is_oauth (optional, deprecated): This property is deprecated and should not be used.

See the [resource types](./meta-3_resources_and_types-index.md) section for a list of supported resource types.
