---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-18
heading_path: ["docker", "Install toolchain and dependencies"]
chunk_type: prose
tokens: 132
summary: "Install toolchain and dependencies"
---

## Install toolchain and dependencies
RUN moon docker setup
```

And with this, our dependencies will be layer cached effectively! Let's now move onto copying source files.

### Copying necessary source files

The next step is to copy all source files necessary for `CMD` or any `RUN` commands to execute correctly. This typically requires copying all source files for the project *and* all source files of the project's dependencies... NOT the entire repository!

Luckily our [`moon docker scaffold <project>`](/docs/commands/docker/scaffold) command has already done this for us! Let's continue updating our `Dockerfile` to account for this, by appending the following:

#### Non-staged

```dockerfile
