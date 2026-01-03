---
id: ops/moonrepo/setup-workspace
title: "Setup workspace"
category: ops
tags: ["setup", "operations", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Setup workspace</title>
  <description>Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace is in charge of:</description>
  <created_at>2026-01-02T19:55:27.234897</created_at>
  <updated_at>2026-01-02T19:55:27.234897</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Initializing the repository" level="2"/>
    <section name="Migrate from an existing build system" level="2"/>
    <section name="Configuring a version control system" level="2"/>
    <section name="Next steps" level="2"/>
  </sections>
  <features>
    <feature>configuring_a_version_control_system</feature>
    <feature>initializing_the_repository</feature>
    <feature>migrate_from_an_existing_build_system</feature>
    <feature>next_steps</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/create-project</entity>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/concepts/workspace</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>setup,operations,moonrepo</tags>
</doc_metadata>
-->

# Setup workspace

> **Context**: Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace

Once moon has been installed, we must setup the workspace, which is denoted by the `.moon` folder — this is known as the workspace root. The workspace is in charge of:

-   Integrating with a version control system.
-   Defining configuration that applies to its entire tree.
-   Housing projects to build a project graph.
-   Running tasks with the action graph.

## Initializing the repository

Let's scaffold and initialize moon in a repository with the `moon init` command. This should typically be ran at the root, but can be nested within a directory.

```
$ moon init
```

When executed, the following operations will be applied.

-   Creates a `.moon` folder with a `.moon/workspace.yml` configuration file.
-   Appends necessary ignore patterns to the relative `.gitignore`.
-   Infers the version control system from the environment.

> If you're investigating moon, or merely want to prototype, you can use `moon init --minimal` to quickly initialize and create minimal configuration files.

## Migrate from an existing build system

Looking to migrate from Nx or Turborepo to moon? Use our `moon ext migrate-nx` or `moon ext migrate-turborepo` commands for a (somewhat) seamless migration!

These extensions will convert your existing configuration files to moon's format as best as possible, but is not a requirement.

## Configuring a version control system

moon requires a version control system (VCS) to be present for functionality like file diffing, hashing, and revision comparison. The VCS and its default branch can be configured through the `vcs` setting.

.moon/workspace.yml

```yaml
vcs:
  manager: 'git'
  defaultBranch: 'master'
```

> moon defaults to `git` and the settings above, so feel free to skip this.

## Next steps

- [Create a project](/docs/create-project)
- [Configure `.moon/workspace.yml` further](/docs/config/workspace)
- [Learn about the workspace](/docs/concepts/workspace)


## See Also

- [Create a project](/docs/create-project)
- [Configure `.moon/workspace.yml` further](/docs/config/workspace)
- [Learn about the workspace](/docs/concepts/workspace)
