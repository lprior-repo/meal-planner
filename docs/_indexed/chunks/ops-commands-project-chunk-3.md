---
doc_id: ops/commands/project
chunk_id: ops/commands/project#chunk-3
heading_path: ["project", "Example output"]
chunk_type: prose
tokens: 172
summary: "Example output"
---

## Example output

The following output is an example of what this command prints, using our very own `@moonrepo/runtime` package.

```
RUNTIME
Project: runtime
Alias: @moonrepo/runtime
Source: packages/runtime
Root: ~/Projects/moon/packages/runtime
Platform: node
Language: typescript
Stack: unknown
Type: library

DEPENDS ON
  - types (implicit, production)

INHERITS FROM
  - .moon/tasks/node.yml

TASKS
build:
  › packemon build --addFiles --addExports --declaration
format:
  › prettier --check --config ../../prettier.config.js --ignore-path ../../.prettierignore --no-error-on-unmatched-pattern .
lint:
  › eslint --cache --cache-location ./.eslintcache --color --ext .js,.ts,.tsx --ignore-path ../../.eslintignore --exit-on-fatal-error --no-error-on-unmatched-pattern --report-unused-disable-directives .
lint-fix:
  › eslint --cache --cache-location ./.eslintcache --color --ext .js,.ts,.tsx --ignore-path ../../.eslintignore --exit-on-fatal-error --no-error-on-unmatched-pattern --report-unused-disable-directives . --fix
test:
  › jest --cache --color --preset jest-preset-moon --passWithNoTests
typecheck:
  › tsc --build

FILE GROUPS
configs:
  - packages/runtime/*.{js,json}
sources:
  - packages/runtime/src/**/*
  - packages/runtime/types/**/*
tests:
  - packages/runtime/tests/**/*
```

### Configuration

- [`projects`](/docs/config/workspace#projects) in `.moon/workspace.yml`
- [`project`](/docs/config/project#project) in `moon.yml`
