---
doc_id: ops/install/kubernetes
chunk_id: ops/install/kubernetes#chunk-5
heading_path: ["Kubernetes", "Updates"]
chunk_type: prose
tokens: 66
summary: "Updates"
---

## Updates

These manifests have been tested for several releases. Newer versions may not work without changes.

If everything works as expected, the `init-chmod-data` initialization container performs the database migration and the update procedure is transparent. However, it is recommended to use specific tags to increase stability and avoid unnecessary migrations.
