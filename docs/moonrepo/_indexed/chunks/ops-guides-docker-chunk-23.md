---
doc_id: ops/guides/docker
chunk_id: ops/guides/docker#chunk-23
heading_path: ["Docker integration", "Prune workspace"]
chunk_type: prose
tokens: 133
summary: "Prune workspace"
---

## Prune workspace
RUN moon docker prune
```

When ran, this command will do the following, in order:

- Remove extraneous dependencies (`node_modules`) for unfocused projects.
- Install production only dependencies for the projects that were scaffolded.

> **Info:** This process can be customized using the `docker.prune` setting in [`.moon/workspace.yaml`](/docs/config/workspace#prune).

### Final result

And with this moon integration, we've reduced the original `Dockerfile` of 35 lines to 18 lines, a reduction of almost 50%. The original file can also be seen as `O(n)`, as each new manifest requires cascading updates, while the moon approach is `O(1)`!

#### Non-staged

```dockerfile
FROM node:latest

WORKDIR /app
