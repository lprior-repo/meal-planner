---
doc_id: ops/docker/scaffold
chunk_id: ops/docker/scaffold#chunk-2
heading_path: ["docker scaffold", "Scaffold a skeleton to .moon/docker"]
chunk_type: prose
tokens: 81
summary: "Scaffold a skeleton to .moon/docker"
---

## Scaffold a skeleton to .moon/docker
$ moon docker scaffold <project>
```

> View the official [Docker usage guide](/docs/guides/docker) for a more in-depth example of how to utilize this command.

### Arguments

-   `<...projects>` - List of project names or aliases to scaffold sources for, as defined in [`projects`](/docs/config/workspace#projects).

### Configuration

-   [`docker.scaffold`](/docs/config/workspace#scaffold) in `.moon/workspace.yml` (entire workspace)
-   [`docker.scaffold`](/docs/config/project#scaffold) in `moon.yml` (per project)
