---
doc_id: tutorial/moonrepo/nest
chunk_id: tutorial/moonrepo/nest#chunk-2
heading_path: ["Nest example", "Setup"]
chunk_type: prose
tokens: 128
summary: "Setup"
---

## Setup

Since NestJS is per-project, the associated moon tasks should be defined in each project's [`moon.yml`](/docs/config/project) file.

<project>/moon.yml

```yaml
layer: 'application'

fileGroups:
  app:
    - 'nest-cli.*'

tasks:
  dev:
    command: 'nest start --watch'
    local: true
  build:
    command: 'nest build'
    inputs:
      - '@group(app)'
      - '@group(sources)'
```

### TypeScript integration

NestJS has [built-in support for TypeScript](https://NestJS.io/guide/typescript-configuration), so there is no need for additional configuration to enable TypeScript support.

At this point we'll assume that a `tsconfig.json` has been created in the application, and typechecking works. From here we suggest utilizing a [global `typecheck` task](/docs/guides/examples/typescript) for consistency across all projects within the repository.
