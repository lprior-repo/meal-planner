---
doc_id: ops/moonrepo/codeowners-2
chunk_id: ops/moonrepo/codeowners-2#chunk-2
heading_path: ["Code owners", "Defining owners"]
chunk_type: code
tokens: 202
summary: "Defining owners"
---

## Defining owners

With moon, you *do not* modify a `CODEOWNERS` file directly. Instead you define owners *per project* with [`moon.yml`](/docs/config/project), or globally with [`.moon/workspace.yml`](/docs/config/workspace). These owners are then aggregated and automatically [synced to a `CODEOWNERS` file](#generating-codeowners).

> **Info:** An owner is a user, team, or group unique to your VCS provider. Please refer to your provider's documentation for the correct format in which to define owners.

### Project-level

For projects, we support an [`owners`](/docs/config/project#owners) setting in [`moon.yml`](/docs/config/project) that accepts file patterns/paths and their owners (contributors required to review), as well as operational settings for minimum required approvals, custom groups, and more.

Paths configured here are relative from the project root, and will be prefixed with the project source (path from workspace root to project root) when the file is synced.

packages/components/moon.yml

```yaml
owners:
  requiredApprovals: 2
  paths:
    'src/': ['@frontend', '@design-system']
    '*.config.js': ['@frontend-infra']
    '*.json': ['@frontend-infra']
```

The configuration above would generate the following:

#### GitHub

.github/CODEOWNERS

```
