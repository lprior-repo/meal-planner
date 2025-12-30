---
doc_id: ops/55_workspace_dependencies/migration
chunk_id: ops/55_workspace_dependencies/migration#chunk-3
heading_path: ["Migration guide", "requirements: ml"]
chunk_type: code
tokens: 126
summary: "requirements: ml"
---

## requirements: ml
```

```typescript
// package_json: api
```

```php
// composer_json: web
```

### 4. Set defaults (optional)

Create unnamed default files to set workspace-wide behavior:

- `/dependencies/requirements.in` - Requirements mode default

This will be referenced by all scripts unless explicitly told otherwise.
Choose one form per language.

:::important
Creation of workspace defaults will redeploy all existing runnables for given language!
:::

### 5. Update CLI

Upgrade to the latest Windmill CLI version that supports workspace dependencies.

### 6. Test

Generate lockfiles and test your scripts:

```bash
wmill script generate-metadata script_path
wmill script run script_path
```
