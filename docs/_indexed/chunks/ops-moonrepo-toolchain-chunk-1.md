---
doc_id: ops/moonrepo/toolchain
chunk_id: ops/moonrepo/toolchain#chunk-1
heading_path: ["Toolchain"]
chunk_type: prose
tokens: 92
summary: ".moon/toolchain.{pkl,yml}"
---

# .moon/toolchain.{pkl,yml}

> **Context**: The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.

The `.moon/toolchain.yml` file configures the toolchain and the workspace development environment. This file is *optional*.

Managing tool version's within the toolchain ensures a deterministic environment across any machine (whether a developer, CI, or production machine).

.moon/toolchain.yml

```yaml
$schema: 'https://moonrepo.dev/schemas/toolchain.json'
```

> Toolchain configuration can also be written in [Pkl](/docs/guides/pkl-config) instead of YAML.
