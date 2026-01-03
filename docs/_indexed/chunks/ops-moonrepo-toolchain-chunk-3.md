---
doc_id: ops/moonrepo/toolchain
chunk_id: ops/moonrepo/toolchain#chunk-3
heading_path: ["Toolchain", "`moon` (v1.29.0)"]
chunk_type: code
tokens: 100
summary: "`moon` (v1.29.0)"
---

## `moon` (v1.29.0)

Configures how moon will receive information about latest releases and download locations.

### `manifestUrl`

Defines an HTTPS URL in which to fetch the current version information from.

.moon/toolchain.yml

```yaml
moon:
  manifestUrl: 'https://proxy.corp.net/moon/version'
```

### `downloadUrl`

Defines an HTTPS URL in which the moon binary can be downloaded from. The download file name is hard-coded and will be appended to the provided URL.

Defaults to downloading from GitHub: https://github.com/moonrepo/moon/releases

.moon/toolchain.yml

```yaml
moon:
  downloadUrl: 'https://github.com/moonrepo/moon/releases/latest/download'
```
