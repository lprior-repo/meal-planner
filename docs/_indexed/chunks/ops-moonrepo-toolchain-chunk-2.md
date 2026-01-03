---
doc_id: ops/moonrepo/toolchain
chunk_id: ops/moonrepo/toolchain#chunk-2
heading_path: ["Toolchain", "`extends`"]
chunk_type: prose
tokens: 97
summary: "`extends`"
---

## `extends`

Defines one or many external `.moon/toolchain.yml`'s to extend and inherit settings from. Perfect for reusability and sharing configuration across repositories and projects. When defined, this setting must be an HTTPS URL *or* relative file system path that points to a valid YAML document!

.moon/toolchain.yml

```yaml
extends: 'https://raw.githubusercontent.com/organization/repository/master/.moon/toolchain.yml'
```

> **Caution**: Settings will be merged recursively for blocks, with values defined in the local configuration taking precedence over those defined in the extended configuration.
