---
doc_id: ops/commands/task
chunk_id: ops/commands/task#chunk-3
heading_path: ["task", "Example output"]
chunk_type: prose
tokens: 119
summary: "Example output"
---

## Example output

The following output is an example of what this command prints, using our very own `@moonrepo/runtime` package.

```
RUNTIME:BUILD

Task: build
Project: runtime
Platform: node
Type: build

PROCESS

Command: packemon build --addFiles --addExports --declaration
Environment variables:
  - NODE_ENV = production
Working directory: ~/Projects/moon/packages/runtime
Runs dependencies: Concurrently
Runs in CI: Yes

DEPENDS ON
  - types:build

INHERITS FROM
  - .moon/tasks/node.yml

INPUTS
  - .moon/*.yml
  - .moon/tasks/node.yml
  - packages/runtime/package.json
  - packages/runtime/src/**/*
  - packages/runtime/tsconfig.*.json
  - packages/runtime/tsconfig.json
  - packages/runtime/types/**/*
  - tsconfig.options.json

OUTPUTS
  - packages/runtime/cjs
```

### Configuration

- [`tasks`](/docs/config/tasks#tasks) in `.moon/tasks.yml`
- [`tasks`](/docs/config/project#tasks) in `moon.yml`
