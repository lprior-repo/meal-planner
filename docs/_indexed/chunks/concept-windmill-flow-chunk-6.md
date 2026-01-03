---
doc_id: concept/windmill/flow
chunk_id: concept/windmill/flow#chunk-6
heading_path: ["Flows", "Update flow inline scripts lockfile"]
chunk_type: prose
tokens: 44
summary: "Update flow inline scripts lockfile"
---

## Update flow inline scripts lockfile

Flows inline script [lockfiles](./meta-windmill-index-17.md) can be also updated locally in the same way as [`wmill script generate-metadata --lock-only`](./concept-windmill-script.md#re-generating-a-script-metadata-file) but for flows' inline scripts:

```bash
wmill flow generate-locks
```text
