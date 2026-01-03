---
doc_id: ops/moonrepo/install
chunk_id: ops/moonrepo/install#chunk-4
heading_path: ["Install moon", "If using workspaces"]
chunk_type: code
tokens: 139
summary: "If using workspaces"
---

## If using workspaces
pnpm add --save-dev -w @moonrepo/cli
```

**Bun:**
```
bun install --dev @moonrepo/cli
```

If you are installing with Bun, you'll need to add `@moonrepo/cli` as a [trusted dependency](https://bun.sh/docs/install/lifecycle#trusteddependencies).

> When a global `moon` binary is executed, and the `@moonrepo/cli` binary exists within the repository, the npm package version will be executed instead. We do this because the npm package denotes the exact version the repository is pinned it.

### Other

moon can also be downloaded and installed manually, by downloading an asset from [https://github.com/moonrepo/moon/releases](https://github.com/moonrepo/moon/releases). Be sure to rename the file after downloading, and apply the executable bit (`chmod +x`) on macOS and Linux.
