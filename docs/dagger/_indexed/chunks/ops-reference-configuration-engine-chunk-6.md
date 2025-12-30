---
doc_id: ops/reference/configuration-engine
chunk_id: ops/reference/configuration-engine#chunk-6
heading_path: ["configuration-engine", "Custom Registries"]
chunk_type: code
tokens: 22
summary: "Mirror Docker Hub to `mirror."
---
Mirror Docker Hub to `mirror.gcr.io`:

```json
{
  "registries": {
    "docker.io": {
      "mirrors": ["mirror.gcr.io"]
    }
  }
}
```
