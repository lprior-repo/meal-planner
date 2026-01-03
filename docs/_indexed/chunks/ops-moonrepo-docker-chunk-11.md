---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-11
heading_path: ["docker", "Build the target"]
chunk_type: prose
tokens: 153
summary: "Build the target"
---

## Build the target
RUN moon run runtime:build
```

For such a small monorepo, this already looks too confusing!!! Let's remedy this by utilizing moon itself to the fullest!

### Scaffolding the bare minimum

The first step in this process is to only copy the bare minimum of files necessary for installing dependencies (Node.js modules, etc). This is typically manifests (`package.json`), lockfiles (`yarn.lock`, etc), and any configuration (`.yarnrc.yml`, etc).

This can all be achieved with the [`moon docker scaffold`](/docs/commands/docker/scaffold) command, which scaffolds a skeleton of the repository structure, with only necessary files (the above). Let's update our `Dockerfile` usage.

#### Non-staged

This assumes [`moon docker scaffold <project>`](/docs/commands/docker/scaffold) is ran outside of the `Dockerfile`.

```dockerfile
FROM node:latest

WORKDIR /app
