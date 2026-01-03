---
doc_id: concept/moonrepo/cheat-sheet
chunk_id: concept/moonrepo/cheat-sheet#chunk-7
heading_path: ["Cheat sheet", "Languages"]
chunk_type: code
tokens: 97
summary: "Languages"
---

## Languages

### Run system binaries available on `PATH`

moon.yml

```yaml
language: 'bash' # batch, etc

tasks:
  example:
    command: 'printenv'
```

moon.yml

```yaml
tasks:
  example:
    command: 'printenv'
    toolchain: 'system'
```

### Run language binaries not supported in moon's toolchain

moon.yml

```yaml
language: 'ruby'

tasks:
  example:
    command: 'rubocop'
    toolchain: 'system'
```

### Run npm binaries (Node.js)

moon.yml

```yaml
language: 'javascript' # typescript

tasks:
  example:
    command: 'eslint'
```

moon.yml

```yaml
tasks:
  example:
    command: 'eslint'
    toolchain: 'node'
```
