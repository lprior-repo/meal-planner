---
doc_id: meta/4_webhooks/index
chunk_id: meta/4_webhooks/index#chunk-3
heading_path: ["Webhooks", "Request with Header"]
chunk_type: prose
tokens: 29
summary: "Request with Header"
---

## Request with Header
curl -X POST \
    --data '{}'                            \
    -H "Content-Type: application/json"    \
    -H "Authorization: Bearer supersecret" \
    ".../w/demo/jobs/run_wait_result/p/u/bot/hello_world_deno"
```

```bash
