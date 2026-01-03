---
doc_id: ops/moonrepo/workspace
chunk_id: ops/moonrepo/workspace#chunk-11
heading_path: [".moon/workspace.{pkl,yml}", "`unstable_remote` (v1.30.0)"]
chunk_type: prose
tokens: 66
summary: "`unstable_remote` (v1.30.0)"
---

## `unstable_remote` (v1.30.0)

Configures a remote service, primarily for cloud-based caching of artifacts. Learn more about this in the [remote caching](/docs/guides/remote-cache) guide.

### `host`

The host URL to communicate with when uploading and downloading artifacts. Supports both `grpc(s)://` and `http(s)://` protocols. This field is required!

.moon/workspace.yml

```yaml
unstable_remote:
  host: 'grpcs://your-host.com:9092'
```
