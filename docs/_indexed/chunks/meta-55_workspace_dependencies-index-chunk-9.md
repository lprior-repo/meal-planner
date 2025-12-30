---
doc_id: meta/55_workspace_dependencies/index
chunk_id: meta/55_workspace_dependencies/index#chunk-9
heading_path: ["Workspace dependencies", "Setting up workspace dependencies"]
chunk_type: code
tokens: 140
summary: "Setting up workspace dependencies"
---

## Setting up workspace dependencies

Requires workspace admin permissions.

1. Go to workspace settings → Dependencies
2. Create new dependencies files

### Creating dependency files

**Python example** (`ml.requirements.in`):
```txt
pandas>=1.5.0
numpy>=1.21.0
scikit-learn==1.1.2
matplotlib>=3.5.0
```

**TypeScript example** (`api.package.json`):
```json
{
  "dependencies": {
    "axios": "^0.27.2",
    "lodash": "^4.17.21",
    "windmill-client": "^1.147.3"
  }
}
```

**PHP example** (`web.composer.json`):
```json
{
  "require": {
    "guzzlehttp/guzzle": "^7.4",
    "monolog/monolog": "^2.8"
  }
}
```

### Setting workspace defaults

Choose default behavior for scripts without annotations:

**Requirements mode default**: Creates `/dependencies/requirements.in`
- Scripts without annotations use this file only
- Import inference disabled by default

:::important
Creation of workspace defaults will redeploy all existing runnables for given language!
:::
