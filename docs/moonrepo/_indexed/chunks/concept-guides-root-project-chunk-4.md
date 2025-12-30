---
doc_id: concept/guides/root-project
chunk_id: concept/guides/root-project#chunk-4
heading_path: ["Root-level project", "Caveats"]
chunk_type: code
tokens: 167
summary: "Caveats"
---

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
