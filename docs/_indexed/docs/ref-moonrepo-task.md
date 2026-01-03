---
id: ref/moonrepo/task
title: "Tasks"
category: ref
tags: ["tasks", "advanced", "reference", "moonrepo"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>build-tools</category>
  <title>Tasks</title>
  <description>Tasks are commands that are ran in the context of a [project](/docs/concepts/project). Underneath the hood, a task is simply a binary or system command that is ran as a child process.</description>
  <created_at>2026-01-02T19:55:26.977460</created_at>
  <updated_at>2026-01-02T19:55:26.977460</updated_at>
  <language>en</language>
  <sections count="10">
    <section name="IDs" level="2"/>
    <section name="Types" level="2"/>
    <section name="Modes" level="2"/>
    <section name="Local only" level="3"/>
    <section name="Internal only (v1.23.0)" level="3"/>
    <section name="Interactive (v1.12.0)" level="3"/>
    <section name="Persistent (v1.6.0)" level="3"/>
    <section name="Configuration" level="2"/>
    <section name="Commands vs Scripts" level="3"/>
    <section name="Inheritance" level="3"/>
  </sections>
  <features>
    <feature>commands_vs_scripts</feature>
    <feature>configuration</feature>
    <feature>inheritance</feature>
    <feature>interactive_v1120</feature>
    <feature>internal_only_v1230</feature>
    <feature>local_only</feature>
    <feature>modes</feature>
    <feature>persistent_v160</feature>
    <feature>types</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/commands/check</entity>
    <entity relationship="uses">/docs/commands/run</entity>
    <entity relationship="uses">/docs/commands/task</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>4</estimated_reading_time>
  <tags>tasks,advanced,reference,moonrepo</tags>
</doc_metadata>
-->

# Tasks

> **Context**: Tasks are commands that are ran in the context of a [project](/docs/concepts/project). Underneath the hood, a task is simply a binary or system comman

Tasks are commands that are ran in the context of a [project](/docs/concepts/project). Underneath the hood, a task is simply a binary or system command that is ran as a child process.

## IDs

A task identifier (or name) is a unique resource for locating a task *within* a project. The ID is explicitly configured as a key within the [`tasks`](/docs/config/project#tasks) setting, and can be written in camel/kebab/snake case. IDs support alphabetic unicode characters, `0-9`, `_`, `-`, `/`, `.`, and must start with a character.

A task ID can be paired with a scope to create a [target](/docs/concepts/target).

## Types

Tasks are grouped into 1 of the following types based on their configured parameters.

-   **Build** - Task generates one or many artifacts, and is derived from the [`outputs`](/docs/config/project#outputs) setting.
-   **Run** - Task runs a one-off, long-running, or never-ending process, and is derived from the [`local`](/docs/config/project#local) setting.
-   **Test** - Task asserts code is correct and behaves as expected. This includes linting, typechecking, unit tests, and any other form of testing. Is the default.

## Modes

Alongside types, tasks can also grouped into a special mode that provides unique handling within the action graph and pipelines.

### Local only

Tasks either run locally, in CI (continuous integration pipelines), or both. For tasks that should *only* be ran locally, for example, development servers and watchers, we provide a mechanism for marking a task as local only. When enabled, caching is turned off, the task will not run in CI, terminal output is not captured, and the task is marked as [persistent](#persistent).

To mark a task as local only, enable the [`local`](/docs/config/project#local) setting.

moon.yml

```yaml
tasks:
  dev:
    command: 'start-dev-server'
    local: true
```

### Internal only (v1.23.0)

Internal tasks are tasks that are not meant to be ran explicitly by the user (via [`moon check`](/docs/commands/check) or [`moon run`](/docs/commands/run)), but are used internally as dependencies of other tasks. Additionally, internal tasks are not displayed in a project's tasks list, but can be inspected with [`moon task`](/docs/commands/task).

To mark a task as internal, enable the [`options.internal`](/docs/config/project#internal) setting.

moon.yml

```yaml
tasks:
  prepare:
    command: 'intermediate-step'
    options:
      internal: true
```

### Interactive (v1.12.0)

Tasks that need to interact with the user via terminal prompts are known as interactive tasks. Because interactive tasks require stdin, and it's not possible to have multiple parallel running tasks interact with stdin, we isolate interactive tasks from other tasks in the action graph. This ensures that only 1 interactive task is ran at a time.

To mark a task as interactive, enable the [`options.interactive`](/docs/config/project#interactive) setting.

moon.yml

```yaml
tasks:
  init:
    command: 'init-app'
    options:
      interactive: true
```

### Persistent (v1.6.0)

Tasks that never complete, like servers and watchers, are known as persistent tasks. Persistent tasks are typically problematic when it comes to dependency graphs, because if they run in the middle of the graph, subsequent tasks will never run because the persistent task never completes!

However in moon, this is a non-issue, as we collect all persistent tasks within the action graph and run them *last as a batch*. This is perfect for a few reasons:

-   All persistent tasks are ran in parallel, so they don't block each other.
-   Running both the backend API and frontend webapp in parallel is a breeze.
-   Dependencies of persistent tasks are guaranteed to have ran and completed.

To mark a task as persistent, enable the [`local`](/docs/config/project#local) or [`options.persistent`](/docs/config/project#persistent) settings.

moon.yml

```yaml
tasks:
  dev:
    command: 'start-dev-server'
    local: true
    # OR
    options:
      persistent: true
```

## Configuration

Tasks can be configured per project through [`moon.yml`](/docs/config/project), or for many projects through [`.moon/tasks.yml`](/docs/config/tasks).

### Commands vs Scripts

A task is either a command or script, but not both. So what's the difference exactly? In the context of a moon task, a command is a single binary execution with optional arguments, configured with the [`command`](/docs/config/project#command) and [`args`](/docs/config/project#args) settings (which both support a string or array). While a script is one or many binary executions, with support for pipes and redirects, and configured with the [`script`](/docs/config/project#script) setting (which is only a string).

A command also supports merging during task inheritance, while a script does not and will always replace values. Refer to the table below for more differences between the 2.

| Feature | Command | Script |
|---------|---------|--------|
| Configured as | string, array | string |
| Inheritance merging | via `mergeArgs` option | always replaces |
| Additional args | via `args` setting | No |
| Passthrough args (from CLI) | Yes | No |
| Multiple commands (with `&&` or `;`) | No | Yes |
| Pipes, redirects, etc | No | Yes |
| Always ran in a shell | No | Yes |
| Custom platform/toolchain | Yes | Yes |
| [Token](/docs/concepts/token) functions and variables | Yes | Yes |

### Inheritance

View the official documentation on [task inheritance](/docs/concepts/task-inheritance).


## See Also

- [project](/docs/concepts/project)
- [`tasks`](/docs/config/project#tasks)
- [target](/docs/concepts/target)
- [`outputs`](/docs/config/project#outputs)
- [`local`](/docs/config/project#local)
