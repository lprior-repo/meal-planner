---
doc_id: ops/guides/docker
chunk_id: ops/guides/docker#chunk-2
heading_path: ["Docker integration", "Requirements"]
chunk_type: prose
tokens: 200
summary: "Requirements"
---

## Requirements

The first requirement, which is very important, is adding `.moon/cache` to the workspace root `.dockerignore` (moon assumes builds are running from the root). Not all files in `.moon/cache` are portable across machines/environments, so copying these file into Docker will definitely cause interoperability issues.

.dockerignore

```
.moon/cache
```

The other requirement depends on how you want to integrate Git with Docker. Since moon executes `git` commands under the hood, there are some special considerations to be aware of when running moon within Docker. There's 2 scenarios to choose from:

1. (recommended) Add the `.git` folder to `.dockerignore`, so that it's not `COPY`'d. moon will continue to work just fine, albeit with some functionality disabled, like caching.
2. Ensure that the `git` library is installed in the container, and copy the `.git` folder with `COPY`. moon will work with full functionality, but it will increase the overall size of the image because of caching.
