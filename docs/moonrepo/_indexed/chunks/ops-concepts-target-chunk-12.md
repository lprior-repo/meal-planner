---
doc_id: ops/concepts/target
chunk_id: ops/concepts/target#chunk-12
heading_path: ["Targets", "Resolves to (assuming project is \"foo\")"]
chunk_type: prose
tokens: 23
summary: "Resolves to (assuming project is \"foo\")"
---

## Resolves to (assuming project is "foo")
tasks:
  lint:
    command: 'eslint'
    deps:
      - 'foo:typecheck'
  typecheck:
    command: 'tsc'
```
