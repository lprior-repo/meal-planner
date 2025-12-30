---
id: ops/commands/task
title: "task"
category: ops
tags: ["commands", "task", "operations"]
---

# task

> **Context**: The `moon task <target>` (or `moon t`) command will display information about a task that has been configured and exists within a project. If a task d

v1.1.0

The `moon task <target>` (or `moon t`) command will display information about a task that has been configured and exists within a project. If a task does not exist, the program will return with a 1 exit code.

```
$ moon task web:build
```

## Arguments

- `<target>` - Fully qualified project + task target.

### Options

- `--json` - Print the task and its configuration as JSON.

## Example output

The following output is an example of what this command prints, using our very own `@moonrepo/runtime` package.

```
RUNTIME:BUILD

Task: build
Project: runtime
Platform: node
Type: build

PROCESS

Command: packemon build --addFiles --addExports --declaration
Environment variables:
  - NODE_ENV = production
Working directory: ~/Projects/moon/packages/runtime
Runs dependencies: Concurrently
Runs in CI: Yes

DEPENDS ON
  - types:build

INHERITS FROM
  - .moon/tasks/node.yml

INPUTS
  - .moon/*.yml
  - .moon/tasks/node.yml
  - packages/runtime/package.json
  - packages/runtime/src/**/*
  - packages/runtime/tsconfig.*.json
  - packages/runtime/tsconfig.json
  - packages/runtime/types/**/*
  - tsconfig.options.json

OUTPUTS
  - packages/runtime/cjs
```

### Configuration

- [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
- [`tasks`](/docs/config/project#tasks) in `moon.yml`


## See Also

- [`tasks`](/docs/config/tasks#tasks)
- [`tasks`](/docs/config/project#tasks)
