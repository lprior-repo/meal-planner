---
id: ops/moonrepo/tasks
title: "query tasks"
category: ops
tags: ["query", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>query tasks</title>
  <description>Use the `moon query tasks` sub-command to query task information for all projects in the project graph. The tasks list can be filtered by passing a [query statement](/docs/concepts/query-lang) as an a</description>
  <created_at>2026-01-02T19:55:26.932500</created_at>
  <updated_at>2026-01-02T19:55:26.932500</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Affected" level="4"/>
    <section name="Filters (v1.30.0)" level="4"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>affected</feature>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>filters_v1300</feature>
    <feature>options</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/docs/concepts/query-lang</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/query-lang</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="3">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>query,operations,moonrepo</tags>
</doc_metadata>
-->

# query tasks

> **Context**: Use the `moon query tasks` sub-command to query task information for all projects in the project graph. The tasks list can be filtered by passing a [q

Use the `moon query tasks` sub-command to query task information for all projects in the project graph. The tasks list can be filtered by passing a [query statement](/docs/concepts/query-lang) as an argument, or by using [options](#options) arguments.

```
## Find all tasks grouped by project
$ moon query tasks

## Find all tasks from projects with an id that matches "react"
$ moon query tasks --id react
$ moon query tasks "task~react"
```

By default, this will output a list of projects, and tasks within the project being indented (with a tab) on their own line, in the format of `<id> | <command> | <type> | <toolchain> | <description>`. If no description is defined, "..." will be displayed instead.

```
web
	lint | eslint | test | node | ...
	test | jest | test | node | ...
app
	format | prettier | test | node | ...
```

The tasks can also be output in JSON by passing the `--json` flag. The output has the following structure:

```
{
	tasks: Record<string, Record<string, Task>>,
	options: QueryOptions,
}
```

### Arguments

- `[query]` - An optional [query statement](/docs/concepts/query-lang) to filter projects with. When provided, all [filter options](#filters) are ignored. v1.4.0

### Options

- `--json` - Display the projects in JSON format.

#### Affected

- `--affected` - Filter tasks that have been affected by touched files.
- `--downstream` - Include downstream dependents of queried tasks. Supports "none" (default), "direct", "deep". v1.30.0
- `--upstream` - Include upstream dependencies of queried tasks. Supports "none", "direct", "deep" (default). v1.30.0

#### Filters (v1.30.0)

All option values are case-insensitive regex patterns.

- `--command <regex>` - Filter tasks that match this command.
- `--id <regex>` - Filter tasks that match this ID.
- `--project <regex>` - Filter tasks that belong to this project.
- `--script <regex>` - Filter tasks that match this script.
- `--toolchain <regex>` - Filter tasks of this toolchain. v1.31.0
- `--type <regex>` - Filter tasks of this type.

### Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
- [`tasks`](/docs/config/project#tasks) in `moon.yml`


## See Also

- [query statement](/docs/concepts/query-lang)
- [options](#options)
- [query statement](/docs/concepts/query-lang)
- [filter options](#filters)
- [`projects`](/docs/config/workspace#projects)
