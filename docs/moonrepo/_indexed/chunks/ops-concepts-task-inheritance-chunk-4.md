---
doc_id: ops/concepts/task-inheritance
chunk_id: ops/concepts/task-inheritance#chunk-4
heading_path: ["Task inheritance", "Global"]
chunk_type: prose
tokens: 28
summary: "Global"
---

## Global
tasks:
  build:
    command:
      - 'webpack'
      - '--mode'
      - 'production'
      - '--color'
    deps:
      - 'designSystem:build'
    inputs:
      - '/webpack.config.js'
    outputs:
      - 'build/'
