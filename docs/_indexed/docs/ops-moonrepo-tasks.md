---
id: ops/moonrepo/tasks
title: "query tasks"
category: ops
tags: ["query", "moonrepo", "operations"]
---

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
