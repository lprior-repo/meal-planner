---
doc_id: tutorial/moonrepo/nest
chunk_id: tutorial/moonrepo/nest#chunk-3
heading_path: ["Nest example", "Configuration"]
chunk_type: prose
tokens: 101
summary: "Configuration"
---

## Configuration

### Root-level

We suggest *against* root-level configuration, as NestJS should be installed per-project, and the `nest` command expects the configuration to live relative to the project root.

### Project-level

When creating a new NestJS project, a [`nest-cli.json`](https://docs.nestjs.com/cli/monorepo) is created, and *must* exist in the project root. This allows each project to configure NestJS for their needs.

<project>/nest-cli.json

```json
{
  "$schema": "https://json.schemastore.org/nest-cli",
  "collection": "@nestjs/schematics",
  "type": "application",
  "root": "./",
  "sourceRoot": "src",
  "compilerOptions": {
    "tsConfigPath": "tsconfig.build.json"
  }
}
```
