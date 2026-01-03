---
id: ops/moonrepo/run
title: "run"
category: ops
tags: ["run", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>run</title>
  <description>The `moon run` (or `moon r`, or `moonx`) command will run one or many [targets](/docs/concepts/target) and all of its dependencies in topological order. Each run will incrementally cache each task, im</description>
  <created_at>2026-01-02T19:55:26.936429</created_at>
  <updated_at>2026-01-02T19:55:26.936429</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Arguments" level="3"/>
    <section name="Options" level="3"/>
    <section name="Debugging" level="4"/>
    <section name="Affected" level="4"/>
    <section name="Configuration" level="3"/>
  </sections>
  <features>
    <feature>affected</feature>
    <feature>arguments</feature>
    <feature>configuration</feature>
    <feature>debugging</feature>
    <feature>options</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/run-task</entity>
    <entity relationship="uses">/docs/cheat-sheet</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/run-task</entity>
    <entity relationship="uses">/docs/concepts/query-lang</entity>
    <entity relationship="uses">/docs/how-it-works/action-graph</entity>
    <entity relationship="uses">/docs/guides/profile</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>run,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# run

> **Context**: The `moon run` (or `moon r`, or `moonx`) command will run one or many [targets](/docs/concepts/target) and all of its dependencies in topological orde

The `moon run` (or `moon r`, or `moonx`) command will run one or many [targets](/docs/concepts/target) and all of its dependencies in topological order. Each run will incrementally cache each task, improving speed and development times... over time. View the official [Run a task](/docs/run-task) and [Cheat sheet](/docs/cheat-sheet#tasks) articles for more information!

```
## Run `lint` in project `app`
$ moon run app:lint
$ moonx app:lint

## Run `dev` in project `client` and `server`
$ moon run client:dev server:dev
$ moonx client:dev server:dev

## Run `test` in all projects
$ moon run :test
$ moonx :test

## Run `test` in all projects with tag `frontend`
$ moon run '#frontend:test'
$ moonx '#frontend:test'

## Run `format` in closest project (`client`)
$ cd apps/client
$ moon run format
$ moonx format

## Run `build` in projects matching the query
$ moon run :build --query "language=javascript && projectType=library"
```

> **info**
> How affected status is determined is highly dependent on whether the command is running locally, in CI, and what options are provided. The following scenarios are possible:
> - When `--affected` is provided, will explicitly use `--remote` to determine CI or local.
> - When not provided, will use `git diff` in CI, or `git status` for local.
> - To bypass affected logic entirely, use `--force`.

> **info**
> The default behavior for `moon run` is to "fail fast", meaning that any failed task will immediately abort execution of the entire action graph. Pass `--no-bail` to execute as many tasks as safely possible (tasks with upstream failures will be skipped to avoid side effects). This is the default behavior for `moon ci`, and is also useful for pre-commit hooks.

### Arguments

- `...<target>` - [Targets](/docs/concepts/target) or project relative tasks to run.
- `[-- <args>]` - Additional arguments to [pass to the underlying command](/docs/run-task#passing-arguments-to-the-underlying-command).

### Options

- `-f`, `--force` - Force run and ignore touched files and affected status. Will not query VCS.
- `--dependents` - Run downstream dependent targets (of the same task name) as well.
- `-i`, `--interactive` - Run the target in an interactive mode.
- `--query` - Filter projects to run targets against using [a query statement](/docs/concepts/query-lang). v1.3.0
- `-s`, `--summary` - Display a summary and stats of the current run. v1.25.0
- `-u`, `--updateCache` - Bypass cache and force update any existing items.
- `--no-actions` - Run the task without running [other actions](/docs/how-it-works/action-graph) in the pipeline. v1.34.0
- `-n`, `--no-bail` - When a task fails, continue executing other tasks instead of aborting immediately

#### Debugging

- `--profile <type>` - Record and [generate a profile](/docs/guides/profile) for ran tasks.
  - Types: `cpu`, `heap`

#### Affected

- `--affected` - Only run target if affected by changed files, *otherwise* will always run.
- `--remote` - Determine affected against remote by comparing `HEAD` against a base revision (default branch), *otherwise* uses local changes.
  - Can control revisions with `MOON_BASE` and `MOON_HEAD`.
- `--status <type>` - Filter affected based on a change status. Can be passed multiple times.
  - Types: `all` (default), `added`, `deleted`, `modified`, `staged`, `unstaged`, `untracked`
- `--stdin` - Accept touched files from stdin for affected checks. v1.36.0

### Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
- [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
- [`tasks`](/docs/config/project#tasks) in `moon.yml`


## See Also

- [targets](/docs/concepts/target)
- [Run a task](/docs/run-task)
- [Cheat sheet](/docs/cheat-sheet#tasks)
- [Targets](/docs/concepts/target)
- [pass to the underlying command](/docs/run-task#passing-arguments-to-the-underlying-command)
