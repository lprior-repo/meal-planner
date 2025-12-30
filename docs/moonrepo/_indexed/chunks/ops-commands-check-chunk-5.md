---
doc_id: ops/commands/check
chunk_id: ops/commands/check#chunk-5
heading_path: ["check", "Check ALL projects (may be costly)"]
chunk_type: prose
tokens: 106
summary: "Check ALL projects (may be costly)"
---

## Check ALL projects (may be costly)
$ moon check --all
```

### Arguments

-   `[...names]` - List of project names or aliases to explicitly check, as defined in [`projects`](/docs/config/workspace#projects).

### Options

-   `--all` - Run check for all projects in the workspace.
-   `-u`, `--updateCache` - Bypass cache and force update any existing items.
-   `--summary` - Display a summary and stats of the current run. v1.25.0

### Configuration

-   [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
-   [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
-   [`tasks`](/docs/config/project#tasks) in `moon.yml`
