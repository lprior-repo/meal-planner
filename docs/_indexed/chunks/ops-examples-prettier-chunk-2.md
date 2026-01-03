---
doc_id: ops/examples/prettier
chunk_id: ops/examples/prettier#chunk-2
heading_path: ["Prettier example", "Setup"]
chunk_type: prose
tokens: 119
summary: "Setup"
---

## Setup

Since code formatting is a universal workflow, add a `format` task to [`.moon/tasks/node.yml`](/docs/config/tasks) with the following parameters.

.moon/tasks/node.yml

```yaml
tasks:
  format:
    command:
      - 'prettier'
      # Use the same config for the entire repo
      - '--config'
      - '@in(4)'
      # Use the same ignore patterns as well
      - '--ignore-path'
      - '@in(3)'
      # Fail for unformatted code
      - '--check'
      # Run in current dir
      - '.'
    inputs:
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Config and other files
      - '**/*.{md,mdx,yml,yaml,json}'
      # Root configs, any format
      - '/.prettierignore'
      - '/.prettierrc.*'
```
