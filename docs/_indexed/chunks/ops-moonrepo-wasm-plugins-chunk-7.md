---
doc_id: ops/moonrepo/wasm-plugins
chunk_id: ops/moonrepo/wasm-plugins#chunk-7
heading_path: ["WASM plugins", "In some job or step..."]
chunk_type: code
tokens: 58
summary: "In some job or step..."
---

## In some job or step...
env:
  GITHUB_TOKEN: '${{ secrets.GITHUB_TOKEN }}'
```

### `https`

The `https://` protocol is your standard URL, and must point to an absolute file path. Files will be downloaded to `~/.moon/plugins` or `~/.proto/plugins`. Non-secure URLs are *not supported*!

```
"https://domain.com/path/to/plugins/example.wasm"
```
