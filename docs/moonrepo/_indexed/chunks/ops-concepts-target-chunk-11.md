---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-11
heading_path: ["Targets", "Configured as"]
chunk_type: prose
tokens: 22
summary: "Configured as"
---

## Configured as
tasks:
  lint:
    command: 'eslint'
    deps:
      - '~:typecheck'
      # OR
      - 'typecheck'
  typecheck:
    command: 'tsc'
