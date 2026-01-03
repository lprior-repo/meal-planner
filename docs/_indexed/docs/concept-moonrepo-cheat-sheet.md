---
id: concept/moonrepo/cheat-sheet
title: "Cheat sheet"
category: concept
tags: ["cheat", "concept", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Cheat sheet</title>
  <description>Don&apos;t have time to read the docs? Here&apos;s a quick cheat sheet to get you started.</description>
  <created_at>2026-01-02T19:55:26.897969</created_at>
  <updated_at>2026-01-02T19:55:26.897969</updated_at>
  <language>en</language>
  <sections count="24">
    <section name="Tasks" level="2"/>
    <section name="Run all build and test tasks for all projects" level="3"/>
    <section name="Run all build and test tasks in a project" level="3"/>
    <section name="Run all build and test tasks for closest project based on working directory" level="3"/>
    <section name="Run a task in all projects" level="3"/>
    <section name="Run a task in all projects with a tag" level="3"/>
    <section name="Run a task in a project" level="3"/>
    <section name="Run multiple tasks in all projects" level="3"/>
    <section name="Run multiple tasks in any project" level="3"/>
    <section name="Run a task in applications, libraries, or tools" level="3"/>
  </sections>
  <features>
    <feature>depend_on_tasks_from_arbitrary_projects</feature>
    <feature>disable_caching</feature>
    <feature>languages</feature>
    <feature>re-run_flaky_tasks</feature>
    <feature>run_a_task_in_a_project</feature>
    <feature>run_a_task_in_all_projects</feature>
    <feature>run_a_task_in_all_projects_with_a_tag</feature>
    <feature>run_dependencies_serially</feature>
    <feature>run_multiple_tasks_in_all_projects</feature>
    <feature>run_multiple_tasks_in_any_project</feature>
    <feature>run_npm_binaries_nodejs</feature>
    <feature>run_system_binaries_available_on_path</feature>
    <feature>task_configuration</feature>
    <feature>tasks</feature>
  </features>
  <dependencies>
    <dependency type="library">react</dependency>
  </dependencies>
  <examples count="23">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>cheat,concept,moonrepo</tags>
</doc_metadata>
-->

# Cheat sheet

> **Context**: Don't have time to read the docs? Here's a quick cheat sheet to get you started.

Don't have time to read the docs? Here's a quick cheat sheet to get you started.

## Tasks

Learn more about tasks and targets.

### Run all build and test tasks for all projects

```
moon check --all
```

### Run all build and test tasks in a project

```
moon check project
```

### Run all build and test tasks for closest project based on working directory

```
moon check
```

### Run a task in all projects

```
moon run :task
```

### Run a task in all projects with a tag

```
moon run '#tag:task'
## OR
moon run \#tag:task
## OR
moon run :task --query "tag=tag"
```

### Run a task in a project

```
moon run project:task
```

### Run multiple tasks in all projects

```
moon run :task1 :task2
```

### Run multiple tasks in any project

```
moon run projecta:task1 projectb:task2
```

### Run a task in applications, libraries, or tools

```
moon run :task --query "projectType=application"
```

### Run a task in projects of a specific language

```
moon run :task --query "language=typescript"
```

### Run a task in projects matching a keyword

```
moon run :task --query "project~react-*"
```

### Run a task in projects based on file path

```
moon run :task --query "projectSource~packages/*"
```

## Task configuration

Learn more about available options.

### Disable caching

moon.yml

```yaml
tasks:
  example:
    # ...
    options:
      cache: false
```

### Re-run flaky tasks

moon.yml

```yaml
tasks:
  example:
    # ...
    options:
      retryCount: 3
```

### Depend on tasks from parent project's dependencies

moon.yml

```yaml
## Also inferred from the language
dependsOn:
  - 'project-a'
  - 'project-b'

tasks:
  example:
    # ...
    deps:
      - '^:build'
```

### Depend on tasks from arbitrary projects

moon.yml

```yaml
tasks:
  example:
    # ...
    deps:
      - 'other-project:task'
```

### Run dependencies serially

moon.yml

```yaml
tasks:
  example:
    # ...
    deps:
      - 'first'
      - 'second'
      - 'third'
    options:
      runDepsInParallel: false
```

### Run multiple watchers/servers in parallel

moon.yml

```yaml
tasks:
  example:
    command: 'noop'
    deps:
      - 'app:watch'
      - 'backend:start'
      - 'tailwind:watch'
    local: true
```

> The `local` or `persistent` settings are required for this to work.

## Languages

### Run system binaries available on `PATH`

moon.yml

```yaml
language: 'bash' # batch, etc

tasks:
  example:
    command: 'printenv'
```

moon.yml

```yaml
tasks:
  example:
    command: 'printenv'
    toolchain: 'system'
```

### Run language binaries not supported in moon's toolchain

moon.yml

```yaml
language: 'ruby'

tasks:
  example:
    command: 'rubocop'
    toolchain: 'system'
```

### Run npm binaries (Node.js)

moon.yml

```yaml
language: 'javascript' # typescript

tasks:
  example:
    command: 'eslint'
```

moon.yml

```yaml
tasks:
  example:
    command: 'eslint'
    toolchain: 'node'
```


## See Also

- [Documentation Index](./COMPASS.md)
