---
doc_id: ops/moonrepo/task-inheritance
chunk_id: ops/moonrepo/task-inheritance#chunk-5
heading_path: ["Task inheritance", "Local"]
chunk_type: prose
tokens: 26
summary: "Local"
---

## Local
tasks:
  build:
    args: '--no-color --no-stats'
    deps:
      - 'reactHooks:build'
    inputs:
      - 'webpack.config.js'
    options:
      mergeArgs: 'append'
      mergeDeps: 'prepend'
      mergeInputs: 'replace'
