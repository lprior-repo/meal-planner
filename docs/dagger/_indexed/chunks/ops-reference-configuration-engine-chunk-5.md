---
doc_id: ops/reference/configuration-engine
chunk_id: ops/reference/configuration-engine#chunk-5
heading_path: ["configuration-engine", "Garbage Collection"]
chunk_type: code
tokens: 39
summary: "Disable the garbage collector:

```json
{
  \"gc\": {
    \"enabled\": false
  }
}
```

Adjust parameter"
---
Disable the garbage collector:

```json
{
  "gc": {
    "enabled": false
  }
}
```

Adjust parameters:

```json
{
  "gc": {
    "maxUsedSpace": "200GB",
    "reservedSpace": "10GB",
    "minFreeSpace": "20%",
    "sweepSize": "50%"
  }
}
```
