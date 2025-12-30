---
doc_id: ops/guides/codeowners
chunk_id: ops/guides/codeowners#chunk-5
heading_path: ["Code owners", "components"]
chunk_type: code
tokens: 144
summary: "components"
---

## components
/packages/components/src/ @frontend @design-system
/packages/components/*.config.js @frontend-infra
/packages/components/*.json @frontend-infra
```

### Workspace-level

Project scoped owners are great but sometimes you need to define owners for files that span across all projects, or files at any depth within the repository. With the [`codeowners.globalPaths`](/docs/config/workspace#globalpaths) setting in [`.moon/workspace.yml`](/docs/config/workspace), you can do just that.

Paths configured here are used as-is, allowing for full control of what ownership is applied.

.moon/workspace.yml

```yaml
codeowners:
  globalPaths:
    # All files
    '*': ['@admins']
    # Config folder at any depth
    'config/': ['@app-platform']
    # GitHub folder at the root
    '/.github/': ['@infra']
```

The configuration above would generate the following at the top of the file (is the same for all providers):

```
