---
doc_id: ops/moonrepo/create-task
chunk_id: ops/moonrepo/create-task#chunk-4
heading_path: ["Create a task", "Using file groups"]
chunk_type: code
tokens: 240
summary: "Using file groups"
---

## Using file groups

Once you're familiar with configuring tasks, you may notice certain inputs being repeated constantly, like source files, test files, and configuration. To reduce the amount of boilerplate required, moon provides a feature known as file groups, which enables grouping of similar file types within a project using file glob patterns or literal file paths.

File groups are defined with the `fileGroups` setting, which maps a list of file paths/globs to a group, like so.

<project>/moon.yml

```yaml
fileGroups:
  configs:
    - '*.config.js'
  sources:
    - 'src/**/*'
    - 'types/**/*'
  tests:
    - 'tests/**/*'
```

We can then replace the inputs in our task above with these new file groups using a syntax known as tokens, specifically the `@globs` and `@files` token functions. Tokens are an advanced feature, so please refer to their documentation for more information!

<project>/moon.yml

```yaml
language: 'javascript'

fileGroups:
  # ...

tasks:
  build:
    command: 'webpack build --mode production --no-stats --output-path @out(0)'
    inputs:
      - '@globs(sources)'
      - 'webpack.config.js'
      - '/webpack-shared.config.js'
    outputs:
      - 'build'
```

With file groups (and tokens), you're able to reduce the amount of configuration required *and* encourage certain file structures for consuming projects!
