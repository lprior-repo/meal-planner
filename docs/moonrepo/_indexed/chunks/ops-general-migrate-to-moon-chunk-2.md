---
doc_id: ops/general/migrate-to-moon
chunk_id: ops/general/migrate-to-moon#chunk-2
heading_path: ["Migrate to moon", "Migrate to moon tasks"]
chunk_type: code
tokens: 315
summary: "Migrate to moon tasks"
---

## Migrate to moon tasks

We suggest using moon tasks (of course), as they provide far more granular control and configurable options than scripts, and a `moon.yml` is a better source of truth. Scripts aren't powerful enough to scale for large codebases.

An example of what this may look like can be found below. This *may* look like a lot, but it pays dividends in the long run.

<project>/moon.yml

```yaml
language: 'javascript'

fileGroups:
  sources:
    - 'src/**/*'
  tests:
    - 'tests/**/*'

tasks:
  build:
    command: 'webpack build --output-path @out(0)'
    inputs:
      - '@globs(sources)'
      - 'webpack.config.js'
    outputs:
      - 'build'

  dev:
    command: 'webpack server'
    inputs:
      - '@globs(sources)'
      - 'webpack.config.js'
    local: true

  format:
    command: 'prettier --check .'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - '/prettier.config.js'

  lint:
    command: 'eslint .'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - '.eslintignore'
      - '.eslintrc.js'
      - '/.eslintrc.js'

  test:
    command: 'jest .'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - 'jest.config.js'

  typecheck:
    command: 'tsc --build'
    inputs:
      - '@globs(sources)'
      - '@globs(tests)'
      - 'tsconfig.json'
      - '/tsconfig.json'
```

To ease the migration process, we offer the `moon migrate from-package-json` command, which will convert a project's `package.json` scripts into `moon.yml` tasks, while also determining project dependencies (`dependsOn`). This needs to be ran *per project*.

```
$ moon migrate from-package-json <project>
```

This command will do its best to parse and convert scripts, but this isn't always a simple 1:1 conversion, especially when determining dependency chains. For this reason alone, we suggest *manually curating* tasks, but the migrate command well get you most of the way!
