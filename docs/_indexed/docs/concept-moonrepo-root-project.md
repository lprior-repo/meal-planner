---
id: concept/moonrepo/root-project
title: "Root-level project"
category: concept
tags: ["rootlevel", "concept", "moonrepo"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>build-tools</category>
  <title>Root-level project</title>
  <description>Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, maintenance, or process oriented tasks can be ran. moon </description>
  <created_at>2026-01-02T19:55:27.193268</created_at>
  <updated_at>2026-01-02T19:55:27.193268</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Caveats" level="2"/>
    <section name="Greedy inputs" level="3"/>
    <section name="Inherited tasks" level="3"/>
  </sections>
  <features>
    <feature>caveats</feature>
    <feature>greedy_inputs</feature>
    <feature>inherited_tasks</feature>
  </features>
  <related_entities>
    <entity relationship="uses">/docs/config/workspace</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/project</entity>
    <entity relationship="uses">/docs/config/tasks</entity>
    <entity relationship="uses">/docs/config/project</entity>
  </related_entities>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>rootlevel,concept,moonrepo</tags>
</doc_metadata>
-->

# Root-level project

> **Context**: Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, mainte

Coming from other repositories or task runner, you may be familiar with tasks available at the repository root, in which one-off, organization, maintenance, or process oriented tasks can be ran. moon supports this through a concept known as a root-level project.

Begin by adding the root to [`projects`](/docs/config/workspace#projects) with a source value of `.` (current directory relative from the workspace).

.moon/workspace.yml

```yaml
## As a map
projects:
  root: '.'

## As a list of globs
projects:
  - '.'
```

> When using globs, the root project's name will be inferred from the repository folder name. Be wary of this as it can change based on what a developer has checked out as.

Once added, create a [`moon.yml`](/docs/config/project) in the root of the repository. From here you can define tasks that can be ran using this new root-level project name, for example, `moon run root:<task>`.

moon.yml

```yaml
tasks:
  versionCheck:
    command: 'yarn version check'
    inputs: []
    options:
      cache: false
```

And that's it, but there are a few caveats to be aware of...

## Caveats

### Greedy inputs

> **Warning:** In moon v1.24, root-level tasks default to no inputs. In previous versions, inputs defaulted to `**/*`. This section is only applicable for older moon versions!

Task [`inputs`](/docs/config/project#inputs) default to `**/*`, which would result in root-level tasks scanning *all* files in the repository. This will be a very expensive operation! We suggest restricting inputs to a very succinct whitelist, or disabling inputs entirely.

moon.yml

```yaml
tasks:
  oneOff:
    # ...
    inputs: []
```

### Inherited tasks

Because a root project is still a project in the workspace, it will inherit all tasks defined in [`.moon/tasks.yml`](/docs/config/tasks), which may be unexpected. To mitigate this, you can exclude some or all of these tasks in the root config with [`workspace.inheritedTasks`](/docs/config/project#inheritedtasks).

moon.yml

```yaml
workspace:
  inheritedTasks:
    include: []
```


## See Also

- [`projects`](/docs/config/workspace#projects)
- [`moon.yml`](/docs/config/project)
- [`inputs`](/docs/config/project#inputs)
- [`.moon/tasks.yml`](/docs/config/tasks)
- [`workspace.inheritedTasks`](/docs/config/project#inheritedtasks)
