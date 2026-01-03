---
id: concept/guides/root-project
title: "Root-level project"
category: concept
tags: ["concept", "guides", "rootlevel"]
---

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
