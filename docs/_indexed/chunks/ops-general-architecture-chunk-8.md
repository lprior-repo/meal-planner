---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-8
heading_path: ["Meal Planner Architecture", "Deployment"]
chunk_type: prose
tokens: 71
summary: "Deployment"
---

## Deployment

### Dagger Pipeline

Dagger builds binaries and deploys to Windmill worker containers:

```
┌──────────┐    ┌──────────┐    ┌─────────────────────┐
│  Source  │───▶│  Dagger  │───▶│  Windmill Workers   │
│  (Rust)  │    │  Build   │    │  /usr/local/bin/*   │
└──────────┘    └──────────┘    └─────────────────────┘
```

Binaries are statically linked and copied into the worker container image or mounted as a volume.
