---
doc_id: ops/moonrepo/typescript
chunk_id: ops/moonrepo/typescript#chunk-2
heading_path: ["TypeScript example", "Setup"]
chunk_type: code
tokens: 149
summary: "Setup"
---

## Setup

Since typechecking is a universal workflow, add a `typecheck` task to [`.moon/tasks/node.yml`](/docs/config/tasks) with the following parameters.

.moon/tasks/node.yml

```yaml
tasks:
  typecheck:
    command:
      - 'tsc'
      # Use incremental builds with project references
      - '--build'
      # Always use pretty output
      - '--pretty'
      # Use verbose logging to see affected projects
      - '--verbose'
    inputs:
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Type declarations
      - 'types/**/*'
      # Project configs
      - 'tsconfig.json'
      - 'tsconfig.*.json'
      # Root configs (extended from only)
      - '/tsconfig.options.json'
    outputs:
      # Matches `compilerOptions.outDir`
      - 'lib'
```

Projects can extend this task and provide additional parameters if need be, for example.

<project>/moon.yml

```yaml
tasks:
  typecheck:
    args:
      # Force build every time
      - '--force'
```
