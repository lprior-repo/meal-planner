---
doc_id: ops/moonrepo/project-2
chunk_id: ops/moonrepo/project-2#chunk-14
heading_path: ["moon.{pkl,yml}", "Example groups"]
chunk_type: code
tokens: 81
summary: "Example groups"
---

## Example groups
fileGroups:
  configs:
    - '*.config.{js,cjs,mjs}'
    - '*.json'
  sources:
    - 'src/**/*'
    - 'types/**/*'
  tests:
    - 'tests/**/*'
    - '**/__tests__/**/*'
  assets:
    - 'assets/**/*'
    - 'images/**/*'
    - 'static/**/*'
    - '**/*.{scss,css}'
```

Once your groups have been defined, you can reference them within [`args`](#args), [`inputs`](#inputs), [`outputs`](#outputs), and more, using [token functions and variables](/docs/concepts/token).

moon.yml

```yaml
tasks:
  build:
    command: 'vite build'
    inputs:
      - '@group(configs)'
      - '@group(sources)'
```
