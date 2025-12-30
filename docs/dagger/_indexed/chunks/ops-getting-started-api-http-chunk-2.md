---
doc_id: ops/getting-started/api-http
chunk_id: ops/getting-started/api-http#chunk-2
heading_path: ["api-http", "Command-line HTTP clients"]
chunk_type: code
tokens: 64
summary: "This example demonstrates how to connect to the Dagger API and run a simple workflow using `curl`..."
---
This example demonstrates how to connect to the Dagger API and run a simple workflow using `curl`:

```bash
echo '{"query":"{
  container {
    from(address:\"alpine:latest\") {
      file(path:\"/etc/os-release\") {
        contents
      }
    }
  }
}"}'|
  dagger run sh -c 'curl -s \
    -u $DAGGER_SESSION_TOKEN: \
    -H "content-type:application/json" \
    -d @- \
    http://127.0.0.1:$DAGGER_SESSION_PORT/query'
```
