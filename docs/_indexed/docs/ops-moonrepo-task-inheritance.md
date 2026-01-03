---
id: ops/moonrepo/task-inheritance
title: "Task inheritance"
category: ops
tags: ["task", "advanced", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Task inheritance</title>
  <description>Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be defined once at the workspace-level, and are then </description>
  <created_at>2026-01-02T19:55:26.973013</created_at>
  <updated_at>2026-01-02T19:55:26.973013</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Scope by project metadata" level="2"/>
    <section name="JavaScript runtimes" level="3"/>
    <section name="Merge strategies" level="2"/>
  </sections>
  <features>
    <feature>javascript_runtimes</feature>
    <feature>merge_strategies</feature>
    <feature>scope_by_project_metadata</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>3</estimated_reading_time>
  <tags>task,advanced,operations,moonrepo</tags>
</doc_metadata>
-->

# Task inheritance

> **Context**: Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be 

Unlike other task runners that require the same tasks to be repeatedly defined for *every* project, moon uses an inheritance model where tasks can be defined once at the workspace-level, and are then inherited by *many or all* projects.

Workspace-level tasks (also known as global tasks) are defined in [`.moon/tasks.yml`](/docs/config/tasks) or [`.moon/tasks/**/*.yml`](/docs/config/tasks), and are inherited by default. However, projects are able to include, exclude, or rename inherited tasks using the [`workspace.inheritedTasks`](/docs/config/project#inheritedtasks) in [`moon.yml`](/docs/config/project).

## Scope by project metadata

By default tasks defined in [`.moon/tasks.yml`](/docs/config/tasks) will be inherited by *all* projects. This approach works well when a monorepo is comprised of a single programming language, but breaks down quickly in multi-language setups.

To support these complex repositories, we support scoped tasks with [`.moon/tasks/**/*.yml`](/docs/config/tasks), where `*.yml` maps to a project based on a combination of its [language](/docs/config/project#language), [stack](/docs/config/project#stack), [layer](/docs/config/project#layer), or [tags](/docs/config/project#tags). This enables you to easily declare tasks for "JavaScript projects", "Go applications", "Ruby libraries", so on and so forth.

When resolving configuration files, moon will locate and *shallow* merge files in the following order, from widest scope to narrowest scope:

-   `.moon/tasks.yml` - All projects.
-   `.moon/tasks/<language>.yml` - Projects with a matching [`language`](/docs/config/project#language) setting.
-   `.moon/tasks/<stack>.yml` - Projects with a matching [`stack`](/docs/config/project#stack) setting. (v1.23.0)
-   `.moon/tasks/<language>-<stack>.yml` - Projects with a matching [`language`](/docs/config/project#language) and [`stack`](/docs/config/project#stack) settings. (v1.23.0)
-   `.moon/tasks/<stack>-<layer>.yml` - Projects with matching [`stack`](/docs/config/project#stack) and [`layer`](/docs/config/project#layer) settings. (v1.23.0)
-   `.moon/tasks/<language>-<layer>.yml` - Projects with matching [`language`](/docs/config/project#language) and [`layer`](/docs/config/project#layer) settings.
-   `.moon/tasks/<language>-<stack>-<layer>.yml` - Projects with matching [`language`](/docs/config/project#language), [`stack`](/docs/config/project#stack), and [`layer`](/docs/config/project#layer) settings. (v1.23.0)
-   `.moon/tasks/tag-<name>.yml` - Projects with a matching [`tag`](/docs/config/project#tags). (v1.2.0)

As mentioned above, all of these files are shallow merged into a single "global tasks" configuration that is unique per-project. Merging **does not** utilize the [merge strategies](#merge-strategies) below, as those strategies are only utilized when merging global and local tasks.

> Tags are resolved in the order they are defined in `moon.yml` `tags` setting.

### JavaScript runtimes

Unlike most languages that have 1 runtime, JavaScript has 3 (Node.js, Deno, Bun), and we must support repositories that are comprised of any combination of these 3. As such, JavaScript (and TypeScript) based projects have the following additional lookups using [`toolchain`](/docs/config/project#toolchain) to account for this:

-   `.moon/tasks/<toolchain>.yml`
-   `.moon/tasks/<toolchain>-<stack>.yml`
-   `.moon/tasks/<toolchain>-<layer>.yml`
-   `.moon/tasks/<toolchain>-<stack>-<layer>.yml`

For example, `node.yml` would be inherited for Node.js projects, `bun-library.yml` for Bun libraries, and `deno-application.yml` for Deno applications. While `javascript.yml`, `typescript-library.yml`, etc, will be inherited for all toolchains.

## Merge strategies

When a [global task](/docs/config/tasks#tasks) and [local task](/docs/config/project#tasks) of the same name exist, they are merged into a single task. To accomplish this, one of many [merge strategies](/docs/config/project#options) can be used.

Merging is applied to the parameters [`args`](/docs/config/project#args), [`deps`](/docs/config/project#deps), [`env`](/docs/config/project#env-1), [`inputs`](/docs/config/project#inputs), and [`outputs`](/docs/config/project#outputs), using the [`merge`](/docs/config/project#merge), [`mergeArgs`](/docs/config/project#mergeargs), [`mergeDeps`](/docs/config/project#mergedeps), [`mergeEnv`](/docs/config/project#mergeenv), [`mergeInputs`](/docs/config/project#mergeinputs) and [`mergeOutputs`](/docs/config/project#mergeoutputs) options respectively. Each of these options support one of the following strategy values.

-   `append` (default) - Values found in the local task are merged *after* the values found in the global task. For example, this strategy is useful for toggling flag arguments.
-   `prepend` - Values found in the local task are merged *before* the values found in the global task. For example, this strategy is useful for applying option arguments that must come before positional arguments.
-   `preserve` - Preserve the original global task values. This should rarely be used, but exists for situations where an inheritance chain is super long and complex, but we simply want to the base values. (v1.29.0)
-   `replace` - Values found in the local task entirely *replaces* the values in the global task. This strategy is useful when you need full control.

All 3 of these strategies are demonstrated below, with a somewhat contrived example, but you get the point.

```yaml
## Global
tasks:
  build:
    command:
      - 'webpack'
      - '--mode'
      - 'production'
      - '--color'
    deps:
      - 'designSystem:build'
    inputs:
      - '/webpack.config.js'
    outputs:
      - 'build/'

## Local
tasks:
  build:
    args: '--no-color --no-stats'
    deps:
      - 'reactHooks:build'
    inputs:
      - 'webpack.config.js'
    options:
      mergeArgs: 'append'
      mergeDeps: 'prepend'
      mergeInputs: 'replace'

## Merged result
tasks:
  build:
    command:
      - 'webpack'
      - '--mode'
      - 'production'
      - '--color'
      - '--no-color'
      - '--no-stats'
    deps:
      - 'reactHooks:build'
      - 'designSystem:build'
    inputs:
      - 'webpack.config.js'
    outputs:
      - 'build/'
    options:
      mergeArgs: 'append'
      mergeDeps: 'prepend'
      mergeInputs: 'replace'
```


## See Also

- [`.moon/tasks.yml`](/docs/config/tasks)
- [`.moon/tasks/**/*.yml`](/docs/config/tasks)
- [`workspace.inheritedTasks`](/docs/config/project#inheritedtasks)
- [`moon.yml`](/docs/config/project)
- [`.moon/tasks.yml`](/docs/config/tasks)
