---
id: ops/moonrepo/target
title: "Targets"
category: ops
tags: ["targets", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Targets</title>
  <description>A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:task`.</description>
  <created_at>2026-01-02T19:55:26.970349</created_at>
  <updated_at>2026-01-02T19:55:26.970349</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Common scopes" level="2"/>
    <section name="By project" level="3"/>
    <section name="By tag (v1.4.0)" level="3"/>
    <section name="Run scopes" level="2"/>
    <section name="All projects" level="3"/>
    <section name="Closest project `~` (v1.33.0)" level="3"/>
    <section name="Config scopes" level="2"/>
    <section name="Dependencies `^`" level="3"/>
    <section name="Self `~`" level="3"/>
  </sections>
  <features>
    <feature>all_projects</feature>
    <feature>by_project</feature>
    <feature>by_tag_v140</feature>
    <feature>closest_project_v1330</feature>
    <feature>common_scopes</feature>
    <feature>config_scopes</feature>
    <feature>dependencies_</feature>
    <feature>run_scopes</feature>
    <feature>self_</feature>
  </features>
  <related_entities>
    <entity relationship="uses"></entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
  </related_entities>
  <examples count="8">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>targets,operations,moonrepo</tags>
</doc_metadata>
-->

# Targets

> **Context**: A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:t

A target is a compound identifier that pairs a [scope](#common-scopes) to a [task](/docs/concepts/task), separated by a `:`, in the format of `scope:task`.

Targets are used by terminal commands...

```bash
$ moon run designSystem:build
```

And configurations for declaring cross-project or cross-task dependencies.

```yaml
tasks:
  build:
    command: 'webpack'
    deps:
      - 'designSystem:build'
```

## Common scopes

These scopes are available for both running targets and configuring them.

### By project

The most common scope is the project scope, which requires the name of a project, as defined in [`.moon/workspace.yml`](/docs/config/workspace). When paired with a task name, it will run a specific task from that project.

```bash
## Run `lint` in project `app`
$ moon run app:lint
```

### By tag (v1.4.0)

Another way to target projects is with the tag scope, which requires the name of a tag prefixed with `#`, and will run a specific task in all projects with that tag.

```bash
## Run `lint` in projects with the tag `frontend`
$ moon run '#frontend:lint'
```

> **Caution**: Because `#` is a special character in the terminal (is considered a comment), you'll need to wrap the target in quotes, or escape it like so `\#`.

## Run scopes

These scopes are only available on the command line when running tasks with `moon run` or `moon ci`.

### All projects

For situations where you want to run a specific target in *all* projects, for example `lint`ing, you can utilize the all projects scope by omitting the project name from the target: `:lint`.

```bash
## Run `lint` in all projects
$ moon run :lint
```

### Closest project `~` (v1.33.0)

If you are within a project folder, or an arbitrarily nested folder, and want to run a task in the closest project (traversing upwards), the `~` scope can be used.

```bash
## Run `lint` in the closest project
$ moon run ~:lint
```

## Config scopes

These scopes are only available when configuring a task.

### Dependencies `^`

When you want to include a reference for each project [that's depended on](/docs/concepts/project#dependencies), you can utilize the `^` scope. This will be expanded to *all* depended on projects. If you do not want all projects, then you'll need to explicitly define them.

moon.yml

```yaml
dependsOn:
  - 'apiClients'
  - 'designSystem'

## Configured as
tasks:
  build:
    command: 'webpack'
    deps:
      - '^:build'

## Resolves to
tasks:
  build:
    command: 'webpack'
    deps:
      - 'apiClients:build'
      - 'designSystem:build'
```

### Self `~`

When referring to another task within the current project, you can utilize the `~` scope, or omit the `~:` prefix altogether, which will be expanded to the current project's name. This is useful for situations where the name is unknown, for example, when configuring [`.moon/tasks.yml`](/docs/config/tasks), or if you just want a shortcut!

.moon/tasks.yml

```yaml
## Configured as
tasks:
  lint:
    command: 'eslint'
    deps:
      - '~:typecheck'
      # OR
      - 'typecheck'
  typecheck:
    command: 'tsc'

## Resolves to (assuming project is "foo")
tasks:
  lint:
    command: 'eslint'
    deps:
      - 'foo:typecheck'
  typecheck:
    command: 'tsc'
```


## See Also

- [scope](#common-scopes)
- [task](/docs/concepts/task)
- [`.moon/workspace.yml`](/docs/config/workspace)
- [that's depended on](/docs/concepts/project#dependencies)
- [`.moon/tasks.yml`](/docs/config/tasks)
