---
id: ref/moonrepo/workspace
title: "Workspace"
category: ref
tags: ["workspace", "reference", "moonrepo"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>build-tools</category>
  <title>Workspace</title>
  <description>A workspace is a directory that contains [projects](/docs/concepts/project), manages a [toolchain](/docs/concepts/toolchain), runs [tasks](/docs/concepts/task), and is coupled with a VCS repository. T</description>
  <created_at>2026-01-02T19:55:26.988951</created_at>
  <updated_at>2026-01-02T19:55:26.988951</updated_at>
  <language>en</language>
  <sections count="1">
    <section name="Configuration" level="2"/>
  </sections>
  <features>
    <feature>configuration</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/concepts/toolchain</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
  </related_entities>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>workspace,reference,moonrepo</tags>
</doc_metadata>
-->

# Workspace

> **Context**: A workspace is a directory that contains [projects](/docs/concepts/project), manages a [toolchain](/docs/concepts/toolchain), runs [tasks](/docs/conce

A workspace is a directory that contains [projects](/docs/concepts/project), manages a [toolchain](/docs/concepts/toolchain), runs [tasks](/docs/concepts/task), and is coupled with a VCS repository. The root of a workspace is denoted by a `.moon` folder.

By default moon has been designed for monorepos, but can also be used for polyrepos.

## Configuration

Configuration that's applied to the entire workspace is defined in [`.moon/workspace.yml`](/docs/config/workspace).


## See Also

- [projects](/docs/concepts/project)
- [toolchain](/docs/concepts/toolchain)
- [tasks](/docs/concepts/task)
- [`.moon/workspace.yml`](/docs/config/workspace)
