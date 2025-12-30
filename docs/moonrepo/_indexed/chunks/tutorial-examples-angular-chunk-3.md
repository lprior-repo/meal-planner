---
doc_id: tutorial/examples/angular
chunk_id: tutorial/examples/angular#chunk-3
heading_path: ["Angular example", "Configuration"]
chunk_type: prose
tokens: 100
summary: "Configuration"
---

## Configuration

### Root-level

We suggest *against* root-level configuration, as Angular should be installed per-project, and the `ng` command expects the configuration to live relative to the project root.

### Project-level

When creating a new Angular project, a [`angular.json`](https://angular.io/guide/workspace-config) is created, and *must* exist in the project root. This allows each project to configure Angular for their needs.

<project>/angular.json

```json
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "projects": {
    "angular-app": {
      "projectType": "application",
      ...
    }
  },
  ...
}
```
