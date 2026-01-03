---
doc_id: ops/commands/setup
chunk_id: ops/commands/setup#chunk-1
heading_path: ["setup"]
chunk_type: prose
tokens: 118
summary: "setup"
---

# setup

> **Context**: The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured t

The `moon setup` command can be used to setup the developer and pipeline environments. It achieves this by downloading and installing all configured tools into the toolchain.

```
$ moon setup
```

> **info**
> This command should rarely be used, as the environment is automatically setup when running other commands, like detecting affected projects, running a task, or generating a build artifact.
