---
id: concept/3_cli/resource
title: "Resources"
category: concept
tags: ["concept", "windmill", "resources", "3_cli"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Resource Commands</title>
  <description>Manage resources via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Resources" level="1"/>
    <section name="Listing resources" level="2"/>
    <section name="Pushing a resource" level="2"/>
    <section name="Resource specification" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>resource_management</feature>
    <feature>resource_push</feature>
    <feature>json_yaml_support</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="2">
    <example>List all resources in workspace</example>
    <example>Push JSON resource to remote</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,cli,wmill,resource,push,list,JSON,YAML</tags>
</doc_metadata>
-->

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Resource Commands</title>
  <description>Manage resources via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Resources" level="1"/>
    <section name="Listing resources" level="2"/>
    <section name="Pushing a resource" level="2"/>
    <section name="Resource specification" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>resource_management</feature>
    <feature>resource_push</feature>
    <feature>json_yaml_support</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="2">
    <example>List all resources in workspace</example>
    <example>Push JSON resource to remote</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>windmill,cli,wmill,resource,push,list,JSON,YAML</tags>
</doc_metadata>
-->

# Resources

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Resource Commands</title> <description>Manage resources via CL

## Listing resources

The `wmill resource` list command is used to list all resources in the remote workspace.

```bash
wmill resource
```text

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


## See Also

- [resource types](./../../core_concepts/3_resources_and_types/index.mdx)
