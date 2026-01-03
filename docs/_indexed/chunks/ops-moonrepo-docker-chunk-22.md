---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-22
heading_path: ["docker", "Build something (optional)"]
chunk_type: prose
tokens: 110
summary: "Build something (optional)"
---

## Build something (optional)
RUN moon run <project>:<task>
```

> **Info:** If you need to copy additional files for your commands to run successfully, you can configure the `docker.scaffold.include` setting in [`.moon/workspace.yaml`](/docs/config/workspace#scaffold) (entire workspace) or [`moon.yml`](/docs/config/project#scaffold) (per project).

### Pruning extraneous files

Now that we've ran a command or built an artifact, we should prune the Docker environment to remove unneeded files and folders. We can do this with the [`moon docker prune`](/docs/commands/docker/prune) command, which *must be ran* within the context of a `Dockerfile`!

```dockerfile
