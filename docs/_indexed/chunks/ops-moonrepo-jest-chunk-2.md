---
doc_id: ops/moonrepo/jest
chunk_id: ops/moonrepo/jest#chunk-2
heading_path: ["Jest example", "Setup"]
chunk_type: code
tokens: 115
summary: "Setup"
---

## Setup

Since testing is a universal workflow, add a `test` task to [`.moon/tasks/node.yml`](/docs/config/tasks) with the following parameters.

.moon/tasks/node.yml

```yaml
tasks:
  test:
    command:
      - 'jest'
      # Always run code coverage
      - '--coverage'
      # Dont fail if a project has no tests
      - '--passWithNoTests'
    inputs:
      # Source and test files
      - 'src/**/*'
      - 'tests/**/*'
      # Project configs, any format
      - 'jest.config.*'
```

Projects can extend this task and provide additional parameters if need be, for example.

<project>/moon.yml

```yaml
tasks:
  test:
    args:
      # Disable caching for this project
      - '--no-cache'
```
