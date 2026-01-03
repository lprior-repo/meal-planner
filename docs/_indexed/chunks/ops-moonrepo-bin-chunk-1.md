---
doc_id: ops/moonrepo/bin
chunk_id: ops/moonrepo/bin#chunk-1
heading_path: ["bin"]
chunk_type: prose
tokens: 153
summary: "bin"
---

# bin

> **Context**: The `moon bin <tool>` command will return an absolute path to a tool's binary within the toolchain. If a tool has not been configured or installed, th

The `moon bin <tool>` command will return an absolute path to a tool's binary within the toolchain. If a tool has not been configured or installed, this will return a 1 or 2 exit code with no value respectively.

```
$ moon bin node
/Users/example/.proto/tools/node/x.x.x/bin/node
```

> A tool is considered "not configured" when not in use, for example, querying yarn/pnpm when the package manager is configured for "npm". A tool is considered "not installed", when it has not been downloaded and installed into the tools directory.
