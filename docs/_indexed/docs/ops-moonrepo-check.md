---
id: ops/moonrepo/check
title: "check"
category: ops
tags: ["check", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>check</title>
  <description>The `moon check [...projects]` (or `moon c`) command will run *all* [build and test tasks](/docs/concepts/task#types) for one or many projects. This is a convenience command for verifying the current </description>
  <created_at>2026-01-02T19:55:26.904124</created_at>
  <updated_at>2026-01-02T19:55:26.904124</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>check,operations,moonrepo</tags>
</doc_metadata>
-->

# check

> **Context**: The `moon check [...projects]` (or `moon c`) command will run *all* [build and test tasks](/docs/concepts/task#types) for one or many projects. This i

The `moon check [...projects]` (or `moon c`) command will run *all* [build and test tasks](/docs/concepts/task#types) for one or many projects. This is a convenience command for verifying the current state of a project, instead of running multiple [`moon run`](/docs/commands/run) commands.

```
## Check project at current working directory
$ moon check

## Check project by name
$ moon check app

## Check multiple projects by name
$ moon check client server

## Check ALL projects (may be costly)
$ moon check --all
```

### Arguments

-   `[...names]` - List of project names or aliases to explicitly check, as defined in [`projects`](/docs/config/workspace#projects).

### Options

-   `--all` - Run check for all projects in the workspace.
-   `-u`, `--updateCache` - Bypass cache and force update any existing items.
-   `--summary` - Display a summary and stats of the current run. v1.25.0

### Configuration

-   [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
-   [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
-   [`tasks`](/docs/config/project#tasks) in `moon.yml`


## See Also

- [build and test tasks](/docs/concepts/task#types)
- [`moon run`](/docs/commands/run)
- [`projects`](/docs/config/workspace#projects)
- [`projects`](/docs/config/workspace#projects)
- [`tasks`](/docs/config/tasks#tasks)
