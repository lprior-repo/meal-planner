---
id: ref/moonrepo/project
title: "Projects"
category: ref
tags: ["projects", "reference", "moonrepo"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>build-tools</category>
  <title>Projects</title>
  <description>A project is a library, application, package, binary, tool, etc, that contains source files, test files, assets, resources, and more. A project must exist and be configured within a [workspace](/docs/</description>
  <created_at>2026-01-02T19:55:26.964081</created_at>
  <updated_at>2026-01-02T19:55:26.964081</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="IDs" level="2"/>
    <section name="Aliases" level="2"/>
    <section name="Dependencies" level="2"/>
    <section name="Configuration" level="2"/>
  </sections>
  <features>
    <feature>aliases</feature>
    <feature>configuration</feature>
    <feature>dependencies</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/concepts/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/concepts/target</entity>
    <entity relationship="uses">/docs/concepts/workspace</entity>
    <entity relationship="uses">/docs/how-it-works/action-graph</entity>
    <entity relationship="uses">/docs/concepts/task</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>projects,reference,moonrepo</tags>
</doc_metadata>
-->

# Projects

> **Context**: A project is a library, application, package, binary, tool, etc, that contains source files, test files, assets, resources, and more. A project must e

A project is a library, application, package, binary, tool, etc, that contains source files, test files, assets, resources, and more. A project must exist and be configured within a [workspace](/docs/concepts/workspace).

## IDs

A project identifier (or name) is a unique resource for locating a project. The ID is explicitly configured within [`.moon/workspace.yml`](/docs/config/workspace), as a key within the [`projects`](/docs/config/workspace#projects) setting, and can be written in camel/kebab/snake case. IDs support alphabetic unicode characters, `0-9`, `_`, `-`, `/`, `.`, and must start with a character.

IDs are used heavily by configuration and the command line to link and reference everything. They're also a much easier concept for remembering projects than file system paths, and they typically can be written with less key strokes.

Lastly, a project ID can be paired with a task ID to create a [target](/docs/concepts/target).

## Aliases

Aliases are a secondary approach for naming projects, and can be used as a drop-in replacement for standard names. What this means is that an alias can also be used when configuring dependencies, or defining [targets](/docs/concepts/target).

However, the difference between aliases and names is that aliases *can not* be explicit configured in moon. Instead, they are specific to a project's primary programming language, and are inferred based on that context (when enabled in settings). For example, a JavaScript or TypeScript project will use the `name` field from its `package.json` as the alias.

Because of this, a project can either be referenced by its name or alias, or both. Choose the pattern that makes the most sense for your company or team!

## Dependencies

Projects can depend on other projects within the [workspace](/docs/concepts/workspace) to build a [project graph](/docs/how-it-works/action-graph), and in turn, an action graph for executing [tasks](/docs/concepts/task). Project dependencies are divided into 2 categories:

-   **Explicit dependencies** - These are dependencies that are explicitly defined in a project's [`moon.yml`](/docs/config/project) config file, using the [`dependsOn`](/docs/config/project#dependson) setting.
-   **Implicit dependencies** - These are dependencies that are implicitly discovered by moon when scanning the repository. How an implicit dependency is discovered is based on the project's [`language`](/docs/config/project#language) setting, and how that language's ecosystem functions.

## Configuration

Projects can be configured with an optional [`moon.yml`](/docs/config/project) in the project root, or through the optional workspace-level [`.moon/tasks.yml`](/docs/config/tasks).


## See Also

- [workspace](/docs/concepts/workspace)
- [`.moon/workspace.yml`](/docs/config/workspace)
- [`projects`](/docs/config/workspace#projects)
- [target](/docs/concepts/target)
- [targets](/docs/concepts/target)
