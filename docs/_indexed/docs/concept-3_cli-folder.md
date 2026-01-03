---
id: concept/3_cli/folder
title: "Folder"
category: concept
tags: ["concept", "windmill", "folder", "3_cli"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>cli</category>
  <title>Windmill CLI Folder Commands</title>
  <description>Manage folders via CLI</description>
  <created_at>2025-12-28T00:00:00Z</created_at>
  <updated_at>2025-12-29T00:00:00Z</updated_at>
  <language>en</language>
  <sections count="2">
    <section name="Folder" level="1"/>
    <section name="Listing folders" level="2"/>
  </sections>
  <features>
    <feature>wmill_cli</feature>
    <feature>folder_management</feature>
    <feature>folder_push</feature>
  </features>
  <dependencies>
    <dependency type="tool">wmill_cli</dependency>
  </dependencies>
  <examples count="1">
    <example>Push local folder specification to remote</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>windmill,cli,wmill,folder,list,push</tags>
</doc_metadata>
-->

# Folder

> **Context**: <!-- <doc_metadata> <type>reference</type> <category>cli</category> <title>Windmill CLI Folder Commands</title> <description>Manage folders via CLI</d

## Listing folders

The `wmill folder` list command is used to list all folders in the remote workspace.

```bash
wmill folder
```text

## Push

The `wmill folder push` command is used to push a local folder specification to a remote location, overriding any existing remote versions.

```bash
wmill folder push <folder_path:string> <remote_path:string>
```

### Arguments

| Argument      | Description                                                      |
| ------------- | ---------------------------------------------------------------- |
| `folder_path` | The path to the local folder.                                    |
| `remote_path` | The path to the remote location where the folder will be pushed. |


## See Also

- [Documentation Index](./COMPASS.md)
