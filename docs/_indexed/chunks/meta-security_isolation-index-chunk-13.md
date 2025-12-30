---
doc_id: meta/security_isolation/index
chunk_id: meta/security_isolation/index#chunk-13
heading_path: ["Security and process isolation", "Use the nsjail image"]
chunk_type: prose
tokens: 26
summary: "Use the nsjail image"
---

## Use the nsjail image
image: ghcr.io/windmill-labs/windmill-ee-nsjail
environment:
  - DISABLE_NSJAIL=false
```

Provides comprehensive isolation including filesystem, network, and resource limits.
