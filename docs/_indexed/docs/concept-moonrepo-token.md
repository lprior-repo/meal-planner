---
id: concept/moonrepo/token
title: "Tokens"
category: concept
tags: ["tokens", "concept", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Tokens</title>
  <description>Tokens are variables and functions that can be used by [`command`](/docs/config/project#command), [`args`](/docs/config/project#args), [`env`](/docs/config/project#env) (&gt;= v1.12), [`inputs`](/docs/co</description>
  <created_at>2026-01-02T19:55:26.981168</created_at>
  <updated_at>2026-01-02T19:55:26.981168</updated_at>
  <language>en</language>
  <sections count="20">
    <section name="Functions" level="2"/>
    <section name="File groups" level="3"/>
    <section name="`@group`" level="3"/>
    <section name="`@dirs`" level="3"/>
    <section name="`@files`" level="3"/>
    <section name="`@globs`" level="3"/>
    <section name="`@root`" level="3"/>
    <section name="`@envs` (v1.21.0)" level="3"/>
    <section name="Inputs &amp; outputs" level="3"/>
    <section name="`@in`" level="3"/>
  </sections>
  <features>
    <feature>datetime</feature>
    <feature>dirs</feature>
    <feature>environment_v1300</feature>
    <feature>envs_v1210</feature>
    <feature>file_groups</feature>
    <feature>files</feature>
    <feature>functions</feature>
    <feature>globs</feature>
    <feature>group</feature>
    <feature>inputs_outputs</feature>
    <feature>meta_v1280</feature>
    <feature>miscellaneous</feature>
    <feature>project</feature>
    <feature>root</feature>
    <feature>task</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>5</estimated_reading_time>
  <tags>tokens,concept,moonrepo</tags>
</doc_metadata>
-->

# Tokens

> **Context**: Tokens are variables and functions that can be used by [`command`](/docs/config/project#command), [`args`](/docs/config/project#args), [`env`](/docs/c

Tokens are variables and functions that can be used by [`command`](/docs/config/project#command), [`args`](/docs/config/project#args), [`env`](/docs/config/project#env) (>= v1.12), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs) when configuring a task. They provide a way of accessing file group paths, referencing values from other task fields, and referencing metadata about the project and task itself.

## Functions

A token function is labeled as such as it takes a single argument, starts with an `@`, and is formatted as `@name(arg)`. The following token functions are available, grouped by their functionality.

> **Caution**: Token functions *must* be the only content within a value, as they expand to multiple files. When used in an `env` value, multiple files are joined with a comma (`,`).

### File groups

These functions reference file groups by name, where the name is passed as the argument.

### `@group`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@group(file_group)` token is a standard token that will be replaced with the file group items as-is, for both file paths and globs. This token merely exists for reusability purposes.

### `@dirs`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@dirs(file_group)` token will be replaced with an expanded list of directory paths, derived from the file group of the same name. If a glob pattern is detected within the file group, it will aggregate all directories found.

> **Warning**: This token walks the file system to verify each directory exists, and filters out those that don't. If using within `outputs`, you're better off using [`@group`](#group) instead.

### `@files`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@files(file_group)` token will be replaced with an expanded list of file paths, derived from the file group of the same name. If a glob pattern is detected within the file group, it will aggregate all files found.

> **Warning**: This token walks the file system to verify each file exists, and filters out those that don't. If using within `outputs`, you're better off using [`@group`](#group) instead.

### `@globs`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@globs(file_group)` token will be replaced with the list of glob patterns as-is, derived from the file group of the same name. If a non-glob pattern is detected within the file group, it will be ignored.

### `@root`

> Usable in `args`, `env`, `inputs`, and `outputs`.

The `@root(file_group)` token will be replaced with the lowest common directory, derived from the file group of the same name. If a glob pattern is detected within the file group, it will walk the file system and aggregate all directories found before reducing.

> When there's no directories, or too many directories, this function will return the project root using `.`.

### `@envs` (v1.21.0)

> Usable in `inputs`.

The `@envs(file_group)` token will be replaced with all environment variables that have been configured in the group of the provided name.

### Inputs & outputs

### `@in`

> Usable in `script` and `args` only.

The `@in(index)` token will be replaced with a single path, derived from [`inputs`](/docs/config/project#inputs) by numerical index. If a glob pattern is referenced by index, the glob will be used as-is, instead of returning the expanded list of files.

### `@out`

> Usable in `script` and `args` only.

The `@out(index)` token will be replaced with a single path, derived from [`outputs`](/docs/config/project#outputs) by numerical index.

### Miscellaneous

### `@meta` (v1.28.0)

> Usable in `command`, `script`, `args`, `env`, `inputs`, and `outputs` only.

The `@meta(key)` token can be used to access project metadata and will be replaced with a value derived from [`project`](/docs/config/project#project) in [`moon.yml`](/docs/config/project).

## Variables

A token variable is a value that starts with `$` and is substituted to a value derived from the current workspace, project, and task. And unlike token functions, token variables can be placed *within* content when necessary, and supports multiple variables within the same content.

### Environment (v1.30.0)

-   `$arch` - The current host architecture, derived from the Rust [`ARCH` constant](https://doc.rust-lang.org/std/env/consts/constant.ARCH.html).
-   `$os` - The current operating system, derived from the Rust [`OS` constant](https://doc.rust-lang.org/std/env/consts/constant.OS.html).
-   `$osFamily` - The current operating system family, either `unix` or `windows`.

### Workspace

-   `$workingDir` - The current working directory.
-   `$workspaceRoot` - Absolute file path to the workspace root.

### Project

Most values are derived from settings in [`moon.yml`](/docs/config/project). When a setting is not defined, or does not have a config, the variable defaults to "unknown" (for enums) or an empty string.

-   `$language` Programming language the project is written in, as defined with [`language`](/docs/config/project#language).
-   `$project` - ID of the project that owns the currently running task, as defined in [`.moon/workspace.yml`](/docs/config/workspace).
-   `$projectAlias` - Alias of the project that owns the currently running task.
-   `$projectChannel` - The discussion channel for the project, as defined with [`project.channel`](/docs/config/project#channel). (v1.28.0)
-   `$projectLayer` - The project layer, as defined with [`layer`](/docs/config/project#layer). (v1.39.0)
-   `$projectName` - The human-readable name of the project, as defined with [`project.name`](/docs/config/project#name). (v1.28.0)
-   `$projectOwner` - The owner of the project, as defined with [`project.owner`](/docs/config/project#name). (v1.28.0)
-   `$projectRoot` - Absolute file path to the project root.
-   `$projectSource` - Relative file path from the workspace root to the project root, as defined in [`.moon/workspace.yml`](/docs/config/workspace).
-   `$projectStack` - The stack of the project, as defined with [`stack`](/docs/config/project#stack). (v1.22.0)
-   `$projectType` - The type of project, as defined with [`type`](/docs/config/project#layer). Deprecated, use `$projectLayer` instead.

### Task

-   `$target` - Fully-qualified target that is currently running.
-   `$task` - ID of the task that is currently running. Does not include the project ID.
-   `$taskToolchain` - The toolchain that task will run against, as defined in [`moon.yml`](/docs/config/project). (v1.31.0)
-   `$taskType` - The [type of task](/docs/concepts/task#types), based on its configured settings.

### Date/Time

-   `$date` - The current date in the format of `YYYY-MM-DD`.
-   `$datetime` - The current date and time in the format of `YYYY-MM-DD_HH:MM:SS`.
-   `$time` - The current time in the format of `HH:MM:SS`.
-   `$timestamp` - The current date and time as a UNIX timestamp in seconds.

### VCS (v1.30.0)

-   `$vcsBranch` - The current branch.
-   `$vcsRepository` - The repository slug, in the format of `owner/repo`.
-   `$vcsRevision` - The current revision (commit, etc).


## See Also

- [`command`](/docs/config/project#command)
- [`args`](/docs/config/project#args)
- [`env`](/docs/config/project#env)
- [`inputs`](/docs/config/project#inputs)
- [`outputs`](/docs/config/project#outputs)
