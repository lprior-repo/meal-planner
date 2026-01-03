---
doc_id: ops/concepts/task-inheritance
chunk_id: ops/concepts/task-inheritance#chunk-6
heading_path: ["Task inheritance", "Merged result"]
chunk_type: prose
tokens: 48
summary: "Merged result"
---

## Merged result
tasks:
  build:
    command:
      - 'webpack'
      - '--mode'
      - 'production'
      - '--color'
      - '--no-color'
      - '--no-stats'
    deps:
      - 'reactHooks:build'
      - 'designSystem:build'
    inputs:
      - 'webpack.config.js'
    outputs:
      - 'build/'
    options:
      mergeArgs: 'append'
      mergeDeps: 'prepend'
      mergeInputs: 'replace'
```
